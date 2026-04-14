from fastapi import FastAPI, HTTPException
from datamodel import UploadRequest
from s3 import generate_upload_url

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

