from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes.uploads import router as uploads_router
from app.db import Base, engine
from app.models import FileUpload


def create_app() -> FastAPI:
    app = FastAPI()

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(uploads_router)
    return app


app = create_app()

# Create tables during startup to keep app boot predictable in new environments.
Base.metadata.create_all(bind=engine)
