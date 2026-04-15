from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import SessionLocal
from app.models import FileUpload
from app.schemas import MetadataRequest, UploadRequest
from app.services import file_exists, generate_upload_url

router = APIRouter()
ALLOWED_TYPES = ["image/jpeg", "image/png"]


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
        raise HTTPException(status_code=400, detail="Missing user_id or ngo_id")

    upload_url, file_url, key = generate_upload_url(req.user_id, req.ngo_id, req.file_type)

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

    existing = db.query(FileUpload).filter(FileUpload.s3_key == req.key).first()
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
    return uploads


@router.get("/uploads/ngo/{ngo_id}/user/{user_id}")
def get_user_uploads(ngo_id: str, user_id: str, db: Session = Depends(get_db)):
    uploads = (
        db.query(FileUpload)
        .filter(FileUpload.ngo_id == ngo_id, FileUpload.user_id == user_id)
        .order_by(FileUpload.created_at.desc())
        .all()
    )
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
        raise HTTPException(status_code=404, detail="No uploads found for this user")

    return {
        "id": upload.id,
        "status": upload.status,
        "ml_result": upload.ml_result,
        "file_url": upload.file_url,
        "created_at": upload.created_at,
    }
