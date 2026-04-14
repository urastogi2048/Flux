from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from database import Base

class FileUpload(Base):
    __tablename__ = "file_uploads"

    id = Column(Integer, primary_key=True, index=True)
    ngo_id = Column(String, index=True)
    user_id = Column(String, index=True)
    s3_key = Column(String, unique=True)  # The address in S3
    file_url = Column(String)             # The permanent S3 URL
    status = Column(String, default="PENDING") # PENDING, PROCESSING, COMPLETED
    ml_result = Column(String, nullable=True)  # To store model output later
    created_at = Column(DateTime, default=datetime.utcnow)