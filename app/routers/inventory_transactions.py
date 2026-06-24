from app.services.inventory_transaction_service import get_all_inventory_transactions, get_inventory_transaction_by_num
from app.schema.inventory_transaction import InventoryTransaction
from fastapi import APIRouter, HTTPException, Query
from app.enums import ApprovalStatus, InventoryTransactionType
from typing import Optional

router = APIRouter(prefix='/inventory-transactions', 
                   tags=['Inventory Transactions'])

@router.get('/', response_model=list[InventoryTransaction])
def read_inventory_transactions(
    trans_status: Optional[ApprovalStatus] = Query(None, alias="status"),
    transaction_type: Optional[InventoryTransactionType] = Query(default=None, alias="type")
):
    return get_all_inventory_transactions(trans_status, transaction_type)

@router.post('/{trans_num}/approve')
def approve_inventory_transaction(
    trans_num: int,
    approver_num: str
):
    approve_inventory_transaction(
        trans_num,
        approver_num
    )

@router.get('/{trans_num}', response_model=InventoryTransaction)
def read_inventory_transaction_by_num(trans_num: int):
    transaction = get_inventory_transaction_by_num(trans_num)
    if transaction is None:
        raise HTTPException(status_code=404, detail='Transaction not found')  
    return transaction