from app.services.inventory_transaction_service import get_all_inventory_transactions
from app.schema.inventory_transaction import InventoryTransaction
from fastapi import APIRouter

router = APIRouter('/inventory-transactions', 
                   tags=['Inventory Transactions'])

@router.get('/', response_model=list[InventoryTransaction])
def read_inventory_transactions():
    return get_all_inventory_transactions()