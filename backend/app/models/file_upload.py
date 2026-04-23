from datetime import datetime

from sqlalchemy import Column, DateTime, Integer, String

from app.db import Base


class FileUpload(Base):
    __tablename__ = "file_uploads"

    id = Column(Integer, primary_key=True, index=True)
    ngo_id = Column(String, index=True)
    user_id = Column(String, index=True)
    s3_key = Column(String, unique=True)
    file_url = Column(String)
    status = Column(String, default="PENDING")
    ml_result = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
