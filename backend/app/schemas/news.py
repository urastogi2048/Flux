from pydantic import BaseModel, Field


class StateNewsRequest(BaseModel):
    state: str = Field(..., min_length=2, max_length=100)
