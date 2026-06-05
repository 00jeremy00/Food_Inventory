import type {InventoryTransaction} from "../../types/inventoryTransaction"
import InventoryTransactionCard from "./inventoryTransactionCard"

type transactionListProps = {
    transaction_list: InventoryTransaction[]
}

function InventoryTransactionList({transaction_list}: transactionListProps){
    return (
        <div>
           {transaction_list.map(transaction => (
               <InventoryTransactionCard key={transaction.transaction_num} inventory_transaction={transaction} />
           ))} 
        </div>
    )
}

export default InventoryTransactionList