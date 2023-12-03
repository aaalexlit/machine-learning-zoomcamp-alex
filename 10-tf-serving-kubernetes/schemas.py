from pydantic import BaseModel
from pydantic.config import ConfigDict

CLASSES = [
    "dress",
    "hat",
    "longsleeve",
    "outwear",
    "pants",
    "shirt",
    "shoes",
    "shorts",
    "skirt",
    "t_shirt",
]


class PredictionOutput(BaseModel):
    dress: float
    hat: float
    longsleeve: float
    outwear: float
    pants: float
    shirt: float
    shoes: float
    shorts: float
    skirt: float
    t_shirt: float


class PredictionInput(BaseModel):
    url: str

    model_config = ConfigDict(
        json_schema_extra={"example": {"url": "http://bit.ly/mlbookcamp-pants"}}
    )
