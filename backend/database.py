import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from config import DATABASE_URL

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,  # This is the "Heartbeat" check
    pool_recycle=300,    # Closes and reopens connections every 5 mins
    pool_size=5,         # Keeps a small number of connections ready
    max_overflow=10      # Allows a few extra if things get busy
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()