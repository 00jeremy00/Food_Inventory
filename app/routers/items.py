from fastapi import APIRouter, HTTPException
from app.schema.item import ItemResponse
from app.services.items_service import (
    get_all_items,
    get_item_by_num
)

router = APIRouter(
    prefix="/items",
    tags=["Items"]
)


@router.get("/", response_model=list[ItemResponse])
def read_items():
    return get_all_items()

@router.get("/{internal_num}", response_model=ItemResponse)
def read_item(internal_num: str):
    return get_item_by_num(internal_num)