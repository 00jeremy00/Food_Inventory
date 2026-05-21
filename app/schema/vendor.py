from pydantic import BaseModel

class VendorResponse(BaseModel):
    vendor_num: str
    vendor_name: str
    phone_number: str
    email: str
    website: str
