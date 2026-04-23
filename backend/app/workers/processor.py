import time

from app.db import SessionLocal
from app.models import FileUpload
from app.services import S3_BUCKET, s3
from app.services.ocr_pipeline import TextExtractor

ocr = TextExtractor()


def fetch_pending_job(db):
    return db.query(FileUpload).filter(FileUpload.status == "PENDING").first()


def run_ocr(image_bytes):
    return ocr.read_text(image_bytes=image_bytes)


def process_job(job, db):
    job.status = "PROCESSING"
    db.commit()

    try:
        obj = s3.get_object(Bucket=S3_BUCKET, Key=job.s3_key)
        image_bytes = obj["Body"].read()

        result_text = run_ocr(image_bytes)

        job.status = "COMPLETED"
        job.ml_result = result_text
        db.commit()
    except Exception:
        job.status = "FAILED"
        db.commit()


def worker_loop():
    while True:
        db = SessionLocal()
        try:
            job = fetch_pending_job(db)
            if job:
                process_job(job, db)
            else:
                time.sleep(3)
        finally:
            db.close()
