import json
import os

from fastapi import APIRouter, Depends, HTTPException
from google import genai
from sqlalchemy.orm import Session

from app.db import SessionLocal
from app.models import FileUpload
from app.schemas import MetadataRequest, StateNewsRequest, UploadRequest
from app.services import (
    file_exists,
    generate_signed_get_url,
    generate_upload_url,
    get_news_alerts_by_state,
)

router = APIRouter()
ALLOWED_TYPES = ["image/jpeg", "image/png", "image/jpg", "application/pdf"]
INDIAN_STATES_AND_UTS = {
    "andhra pradesh",
    "arunachal pradesh",
    "assam",
    "bihar",
    "chhattisgarh",
    "goa",
    "gujarat",
    "haryana",
    "himachal pradesh",
    "jharkhand",
    "karnataka",
    "kerala",
    "madhya pradesh",
    "maharashtra",
    "manipur",
    "meghalaya",
    "mizoram",
    "nagaland",
    "odisha",
    "punjab",
    "rajasthan",
    "sikkim",
    "tamil nadu",
    "telangana",
    "tripura",
    "uttar pradesh",
    "uttarakhand",
    "west bengal",
    "andaman and nicobar islands",
    "chandigarh",
    "dadra and nagar haveli and daman and diu",
    "delhi",
    "jammu and kashmir",
    "ladakh",
    "lakshadweep",
    "puducherry",
}


class NGOTaskGenerator:
    def __init__(self, model_name: str = "models/gemini-2.5-flash"):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY is not configured")
        self.client = genai.Client(api_key=api_key)
        self.model_name = model_name

    def generate_task(self, description: str) -> dict:
        prompt = f"""
You are an intelligent NGO task planner.

Generate a practical NGO task.

STRICT RULES:
- Output ONLY valid JSON
- No explanation
- No markdown
- No extra text
- Use double quotes
- All fields must be present

Input:
{{
    "description": "{description}"
}}

Output format:
{{
    "task_id": "",
    "title": "",
    "category": "",
    "location": "",
    "objective": "",
    "required_resources": {{
        "volunteers": 0,
        "skills": [],
        "materials": []
    }},
    "timeline": {{
        "deadline": "",
        "estimated_duration_hours": 0
    }},
    "priority": "",
    "notes": ""
}}
"""

        response = self.client.models.generate_content(
            model=self.model_name,
            contents=prompt,
            config={"response_mime_type": "application/json"},
        )

        try:
            return json.loads(response.text)
        except (json.JSONDecodeError, TypeError):
            raise HTTPException(
                status_code=502,
                detail="LLM returned invalid JSON response",
            )


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/get_upload_url")
def get_upload_url(req: UploadRequest):
    if req.file_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail="Invalid File Type")
    if not req.user_id or not req.ngo_id:
        raise HTTPException(
            status_code=400, detail="Missing user_id or ngo_id")

    upload_url, file_url, key = generate_upload_url(
        req.user_id, req.ngo_id, req.file_type)

    return {
        "upload_url": upload_url,
        "file_url": file_url,
        "key": key,
    }


@router.post("/save-metadata")
def save_metadata(req: MetadataRequest, db: Session = Depends(get_db)):
    expected_prefix = f"uploads/{req.ngo_id}/{req.user_id}/"
    if not req.key.startswith(expected_prefix):
        raise HTTPException(status_code=400, detail="Invalid key structure")

    if not file_exists(req.key):
        raise HTTPException(status_code=400, detail="File not found in S3")

    existing = db.query(FileUpload).filter(
        FileUpload.s3_key == req.key).first()
    if existing:
        return {"message": "Already exists"}

    new_file = FileUpload(
        ngo_id=req.ngo_id,
        user_id=req.user_id,
        s3_key=req.key,
        file_url=req.file_url,
        status="PENDING",
    )

    db.add(new_file)
    db.commit()

    return {"message": "Metadata saved successfully"}


@router.get("/uploads/ngo/{ngo_id}")
def get_ngo_uploads(ngo_id: str, db: Session = Depends(get_db)):
    uploads = db.query(FileUpload).filter(FileUpload.ngo_id == ngo_id).all()
    for upload in uploads:
        if upload.s3_key:
            upload.file_url = generate_signed_get_url(upload.s3_key)
    return uploads


@router.get("/uploads/ngo/{ngo_id}/user/{user_id}")
def get_user_uploads(ngo_id: str, user_id: str, db: Session = Depends(get_db)):
    uploads = (
        db.query(FileUpload)
        .filter(FileUpload.ngo_id == ngo_id, FileUpload.user_id == user_id)
        .order_by(FileUpload.created_at.desc())
        .all()
    )
    for upload in uploads:
        if upload.s3_key:
            upload.file_url = generate_signed_get_url(upload.s3_key)
    return uploads


@router.get("/uploads/status/latest")
def get_latest_upload_status(ngo_id: str, user_id: str, db: Session = Depends(get_db)):
    upload = (
        db.query(FileUpload)
        .filter(FileUpload.ngo_id == ngo_id, FileUpload.user_id == user_id)
        .order_by(FileUpload.created_at.desc())
        .first()
    )

    if not upload:
        raise HTTPException(
            status_code=404, detail="No uploads found for this user")

    return {
        "id": upload.id,
        "status": upload.status,
        "ml_result": upload.ml_result,
        "file_url": generate_signed_get_url(upload.s3_key) if upload.s3_key else upload.file_url,
        "created_at": upload.created_at,
    }


@router.post("/uploads/ngo/{ngo_id}/generate-task")
def generate_ngo_task_from_ml_output(ngo_id: str, db: Session = Depends(get_db)):
    rows = (
        db.query(FileUpload.ml_result)
        .filter(FileUpload.ngo_id == ngo_id, FileUpload.ml_result.isnot(None))
        .all()
    )

    combined_ml_output = "\n".join(
        item[0].strip() for item in rows if item[0] and item[0].strip()
    )

    if not combined_ml_output:
        raise HTTPException(
            status_code=404,
            detail="No ML output found for the provided ngo_id",
        )

    try:
        generator = NGOTaskGenerator()
        task_json = generator.generate_task(combined_ml_output)
    except ValueError as exc:
        raise HTTPException(status_code=500, detail=str(exc))
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=502, detail=f"Task generation failed: {exc}")

    return task_json


@router.post("/news/by-state")
def get_news_by_state(req: StateNewsRequest):
    state = req.state.strip()
    if state.lower() not in INDIAN_STATES_AND_UTS:
        raise HTTPException(
            status_code=400,
            detail="Invalid Indian state or union territory",
        )

    try:
        result = get_news_alerts_by_state(state)
    except Exception as exc:
        raise HTTPException(
            status_code=502, detail=f"News pipeline failed: {exc}")

    return {
        "message": "News alerts fetched successfully",
        "data": result,
    }
