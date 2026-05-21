from pydantic import BaseModel
from decimal import Decimal


class ItemResponse(BaseModel):
    internal_num: str
    internal_name: str
    category: str
    internal_unit: str
    total_quantity: Decimal
    total_value: Decimal