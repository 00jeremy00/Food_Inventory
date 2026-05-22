from pydantic import BaseModel
from decimal import Decimal
from datetime import datetime
from typing import Optional
from app.enums import BatchTransactionType, ApprovalStatus

class BatchTransaction(BaseModel):
    transaction_num: int
    batch_num: int
    quantity: Decimal
    transaction_type: BatchTransactionType
    transaction_date: datetime
    created_by: str
    creator_name: str
    approved_by: Optional[str] = None
    approver_name: Optional[str] = None
    approval_status: ApprovalStatus
    reason: Optional[str] = None