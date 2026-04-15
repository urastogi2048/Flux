from database import SessionLocal
from database_models import FileUpload
from s3 import s3, S3_BUCKET
from sqlalchemy import select
import time
from ocr_pipeline import TextExtractor

ocr=TextExtractor()

def fetch_pending_job(db):
    return db.query(FileUpload).filter(FileUpload.status == "PENDING").first()


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

    except Exception as e:
        job.status = "FAILED"
        db.commit()


def run_ocr(image_bytes):
    return ocr.read_text(image_bytes=image_bytes)


def worker_loop():
    while True:
        db = SessionLocal()

        job = fetch_pending_job(db)

        if job:
            process_job(job, db)
        else:
            time.sleep(3)  # avoid hammering DB

        db.close()


if __name__ == "__main__":
    worker_loop()