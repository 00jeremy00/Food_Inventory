from pydantic import BaseModel
from decimal import Decimal
from datetime import datetime
from typing import Optional
from app.enums import InventoryTransactionType, ApprovalStatus

class InventoryTransaction(BaseModel):
    transaction_num: int
    transaction_type: InventoryTransactionType
    quantity: Decimal
    transaction_date: datetime
    approved_by: Optional[str] = None
    approver_name: Optional[str] = None
    created_by: str
    creator_name: str
    approval_status: ApprovalStatus
    invoice_id: Optional[int] = None
    product_num: int
    price_per_unit: Decimal
    batch_num: Optional[int] = None
    reason: Optional[str] = None