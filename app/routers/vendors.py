from fastapi import APIRouter, HTTPException
from app.schema.vendor import VendorResponse
from app.services.vendors_service import (
    get_all_vendors,
    get_vendor_by_num
)

router = APIRouter(
    prefix="/vendors",
    tags=["Vendors"]
)

@router.get("/", response_model=list[VendorResponse])
def read_items():
    return get_all_vendors()

@router.get("/{vendor_num}", response_model=VendorResponse)
def read_item(vendor_num: str):
    return get_vendor_by_num(vendor_num)