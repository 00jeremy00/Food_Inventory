from fastapi import APIRouter, HTTPException, Query
from app.services.invoice_lines_service import get_all_invoice_lines
from app.schema.invoice_line import InvoiceLine
from typing import Optional
router = APIRouter(
    prefix='/invoice-lines', tags=['Invoice Lines']
)

@router.get('/', response_model=list[InvoiceLine])
def read_invoice_lines(
    product_num: Optional[int] = Query(None, alias='product-num'),
    invoice_id: Optional[int] = Query(None, alias='invoice-id')
):
    invoice_lines = get_all_invoice_lines(product_num, invoice_id)
    if not invoice_lines:
        raise HTTPException(status_code=404, detail='No invoice lines found')
    return invoice_lines
