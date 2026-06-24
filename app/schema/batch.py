from pydantic import BaseModel
from decimal import Decimal
from datetime import datetime
from typing import Optional
from app.enums import BatchStatus


class BatchResponse(BaseModel):
    batch_num: int
    recipe_num: int
    recipe_name: str
    created_on: Optional[datetime] = None
    created_by: str
    created_by_name: str
    approved_by: Optional[str] = None
    approved_by_name: Optional[str] = None
    plan_num: Optional[int] = None
    prepared_quantity: Decimal
    remaining_quantity: Decimal
    recipe_unit: str
    depleted_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    batch_status: BatchStatus
    par: Decimal