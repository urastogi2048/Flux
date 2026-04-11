from pydantic import BaseModel
from typing import Optional, List


class NGOInput(BaseModel):
    description: str
