import type { InventoryTransaction } from "../../types/inventoryTransaction";
//import "./inventoryTransaction.css"

type InventoryTransactionProps = {
    inventory_transaction: InventoryTransaction
}

function InventoryTransactionCard({inventory_transaction} : InventoryTransactionProps ){
    const isApproved = inventory_transaction.approval_status == 'APPROVED'
    const headerClass = isApproved ? "headerGreen" : "headerRed"

    return (
        <div className="inventoryTransactionCard">
            <div className={`cardHeader ${headerClass}`}>
                <h3>Transaction {inventory_transaction.transaction_num}</h3> 
            </div>

            <div className="cardContent">
                <p>{inventory_transaction.transaction_type} {inventory_transaction.quantity} {inventory_transaction.internal_units}</p> 
                <p>Status: {inventory_transaction.approval_status}</p>
            </div>
            {inventory_transaction.approval_status == 'PENDING' && (
                <button className='approveTransButton'>Approve</button>
            )}
      </div>
    )
}

export default InventoryTransactionCard