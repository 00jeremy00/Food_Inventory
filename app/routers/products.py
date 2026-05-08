from fastapi import APIRouter, HTTPException
from app.schema.product import ProductResponse
from app.services.products_service import (
    get_all_products,
    get_product_by_num
)

router = APIRouter(
    prefix="/products",
    tags=["Products"]
)


@router.get("/", response_model=list[ProductResponse])
def read_products():
    return get_all_products()


@router.get("/{product_num}", response_model=ProductResponse)
def read_product(product_num: int):

    product = get_product_by_num(product_num)

    if not product:
        raise HTTPException(
            status_code=404,
            detail="Product not found"
        )   

    return product
