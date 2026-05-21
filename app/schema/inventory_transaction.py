from pydantic import BaseModel
from decimal import Decimal
from datetime import datetime
from app.enums import InventoryTransactionType, ApprovalStatus

class InventoryTransaction(BaseModel):
    transaction_num: int
    transaction_type: InventoryTransactionType
    quantity: Decimal
    transaction_date: datetime
    approved_by: str
    approver_name: str
    created_by: str
    creator_name: str
    approval_status: ApprovalStatus
    invoice_id: int
    product_num: int
    price_per_unit: Decimal
    batch_num: int
    reason: str