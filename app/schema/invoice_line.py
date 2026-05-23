from pydantic import BaseModel
from decimal import Decimal

class InvoiceLine(BaseModel):
    invoice_id: int
    product_num: int
    vendor_pname: str
    internal_num: str
    quantity: Decimal
    line_price: Decimal
    purchase_unit: str
