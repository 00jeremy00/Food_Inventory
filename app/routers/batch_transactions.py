from fastapi import APIRouter, Query, HTTPException
from typing import Optional
from app.schema.batch_transaction import BatchTransaction
from app.services.batch_transactions_service import get_all_batch_transactions, get_batch_transaction_by_num

router = APIRouter(prefix='/batch-transactions', 
    tags=['Batch Transactions'])

@router.get('/', response_model=list[BatchTransaction])
def read_batch_transactions(
    trans_status: Optional[str] = Query(None, alias="status"),
    trans_type: Optional[str] = Query(default=None, alias="type")
):
    return get_all_batch_transactions(trans_status, trans_type)

@router.get('/{batch_num}', response_model=BatchTransaction)
def read_batch_transaction_by_num(batch_num: int):
    batch_transaction = get_batch_transaction_by_num(batch_num)
    if batch_transaction is None:
        raise HTTPException(status_code=404, detail='Batch Transaction not found')  
    return batch_transaction