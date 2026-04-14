from fastapi import FastAPI, HTTPException
from pydantic_models import UploadRequest,MetadataRequest
from s3 import generate_upload_url,file_exists
from database import engine,SessionLocal
import database_models

database_models.Base.metadata.create_all(bind=engine)

app=FastAPI()

ALLOWED_TYPES=["image/jpeg", "image/png"]

@app.post("/get_upload_url")
def get_upload_url(req: UploadRequest):
    if req.file_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail="Invalid File Type")
    if not req.user_id or not req.ngo_id:
        raise HTTPException(status_code=400, detail="Missing user_id or ngo_id")
    
    upload_url,file_url,key=generate_upload_url(
        req.user_id,
        req.ngo_id,
        req.file_type
    )

    return {
        "upload_url":upload_url,
        "file_url":file_url,
        "key":key
    }

@app.post("/save-metadata")
def save_metadata(req: MetadataRequest):

    db = SessionLocal()

    expected_prefix = f"uploads/{req.ngo_id}/{req.user_id}/"
    if not req.key.startswith(expected_prefix):
        raise HTTPException(status_code=400, detail="Invalid key structure")

    if not file_exists(req.key):
        raise HTTPException(status_code=400, detail="File not found in S3")

    existing = db.query(database_models.FileUpload).filter(database_models.FileUpload.s3_key == req.key).first()
    if existing:
        return {"message": "Already exists"}

    new_file = database_models.FileUpload(
        ngo_id=req.ngo_id,
        user_id=req.user_id,
        s3_key=req.key,
        file_url=req.file_url,
        status="PENDING"
    )

    db.add(new_file)
    db.commit()

    return {"message": "Metadata saved successfully"}