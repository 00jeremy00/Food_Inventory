from pydantic import BaseModel
from decimal import Decimal


class ProductResponse(BaseModel):
    product_num: int
    vendor_pnum: str
    vendor_pname: str
    purchase_unit: str
    price: Decimal
    conversion_factor: Decimal
    internal_num: str
    internal_name: str
    internal_unit: str
    vendor_num: str
    vendor_name: str
    inventory_quantity: Decimal