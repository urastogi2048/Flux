import boto3
import uuid
from config import AWS_ACCESS_KEY, AWS_SECRET_KEY, AWS_REGION, S3_BUCKET

print("AWS_ACCESS_KEY:  ",AWS_ACCESS_KEY)
print("AWS_SECRET_KEY:  ",AWS_SECRET_KEY)

s3 = boto3.client(
    "s3",
    region_name=AWS_REGION,
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
    config=boto3.session.Config(signature_version='s3v4', s3={'addressing_style': 'virtual'})
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
            "ServerSideEncryption": "AES256"
        },
        ExpiresIn=5000
    )
    file_url = f"https://{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{key}"
    return upload_url, file_url, key

"""await fetch(upload_url, {
    method: 'PUT',
    body: fileBlob,
    headers: {
        'Content-Type': file_type,
        'x-amz-server-side-encryption': 'AES256' // Must match what FastAPI signed
    }
});"""