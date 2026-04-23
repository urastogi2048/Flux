from pydantic import BaseModel


class UploadRequest(BaseModel):
    user_id: str
    ngo_id: str
    file_type: str


class MetadataRequest(BaseModel):
    user_id: str
    ngo_id: str
    key: str
    file_url: str
