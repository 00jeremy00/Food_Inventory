import type { InventoryTransaction } from "../../types/inventoryTransaction";

type InventoryTransactionProps = {
    inventory_transaction: InventoryTransaction
}

function InventoryTransactionCard({inventory_transaction} : InventoryTransactionProps ){
    return (
        <div>
          <h3>Transaction {inventory_transaction.transaction_num}</h3> 
          <p>{inventory_transaction.transaction_type} {inventory_transaction.quantity} {inventory_transaction.internal_units}</p> 
          <p>Status: {inventory_transaction.approval_status}</p>
        </div>
    )
}

export default InventoryTransactionCard