from pydantic import BaseModel
from app.enums import ApprovalStatus
from typing import Optional
from datetime import datetime 


class Invoice(BaseModel):
    invoice_id: int
    invoice_num: str
    invoice_date: datetime
    vendor_num: str
    approval_status: ApprovalStatus
    approved_by: Optional[str] = None
    approved_by_name: Optional[str] = None
