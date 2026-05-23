from fastapi import APIRouter, HTTPException, Query
from app.services.invoices_service import get_all_invoices, get_invoice_by_num
from app.schema.invoice import Invoice
from typing import Optional
from app.enums import ApprovalStatus


router = APIRouter(prefix='/invoices', tags=['Invoices'])

@router.get('/', response_model=list[Invoice])
def read_invoices(
    approval_status: Optional[ApprovalStatus] = Query(None, alias='status')):
    invoices = get_all_invoices(approval_status)
    if not invoices:
        raise HTTPException(status_code=404, detail='No invoices found')
    return invoices

@router.get('/{invoice_num}', response_model=Invoice)
def read_invoice_by_num(invoice_num:str):
    invoice = get_invoice_by_num(invoice_num)
    if not invoice:
        raise HTTPException(status_code=404, detail='Invoice not found')
    return invoice