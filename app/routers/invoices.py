from fastapi import APIRouter, HTTPException
from app.services.invoices_service import get_all_invoices, get_invoice_by_num
from app.schema.invoice import Invoice


router = APIRouter(prefix='/invoices', tags=['Invoices'])

@router.get('/', response_model=list[Invoice])
def read_invoices():
    invoices = get_all_invoices()
    if not invoices:
        raise HTTPException(status_code=404, detail='No invoices found')
    return invoices

@router.get('/{invoice_num}', response_model=Invoice)
def read_invoice_by_num(invoice_num:str):
    invoice = get_invoice_by_num(invoice_num)
    if not invoice:
        raise HTTPException(status_code=404, detail='Invoice not found')
    return invoice