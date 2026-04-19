import uuid

import boto3

from app.core.config import AWS_ACCESS_KEY, AWS_REGION, AWS_SECRET_KEY, S3_BUCKET

s3 = boto3.client(
    "s3",
    region_name=AWS_REGION,
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
    config=boto3.session.Config(signature_version="s3v4", s3={"addressing_style": "virtual"}),
)


def generate_upload_url(user_id: str, ngo_id: str, file_type: str):
    ext = file_type.split("/")[-1]
    file_id = str(uuid.uuid4())

    key = f"uploads/{ngo_id}/{user_id}/{file_id}.{ext}"
    upload_url = s3.generate_presigned_url(
        ClientMethod="put_object",
        Params={
            "Bucket": S3_BUCKET,
            "Key": key,
            "ContentType": file_type,
            "ServerSideEncryption": "AES256",
        },
        ExpiresIn=5000,
    )
    #file_url = f"https://{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{key}"
    file_url = s3.generate_presigned_url(
        ClientMethod="get_object",
        Params={
            "Bucket": S3_BUCKET,
            "Key": key,
        },
        ExpiresIn=604800,  # 7 days
    )
    return upload_url, file_url, key


def file_exists(key: str) -> bool:
    try:
        s3.head_object(Bucket=S3_BUCKET, Key=key)
        return True
    except Exception:
        return False
