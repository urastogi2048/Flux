from pydantic import BaseModel
from typing import Optional, List


class NGOInput(BaseModel):
    location: str
    category: str
    beneficiaries: int

    situation: str

    description: str
