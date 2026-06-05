import { useEffect, useState } from "react"
import { fetchItems } from "../api/itemsApi"
import ItemList  from "../components/items/itemList"
import DashboardPane from "../components/layout/dashboardPane"

import type {Item} from "../types/items"
import type { InventoryTransaction } from "../types/inventoryTransaction"
import InventoryTransactionList from "../components/inventory_transactions/inventoryTransactionList"
import { fetchInventoryTransactions } from "../api/inventoryTransactionsApi"

function Dashboard(){
    const [items, setItems] = useState<Item[]>([])
    const [inventoryTransactions, setInventoryTransactions] = useState<InventoryTransaction[]>([])

    useEffect(() => {
        async function loadItems(){
            try {
                const data = await fetchItems()
                setItems(data)
            }
            catch (error){
                console.error(error)
            }
        }

        async function loadInventoryTransactions() {
            try {
                const data = await fetchInventoryTransactions()
                setInventoryTransactions(data)
            } catch (error) {
                console.error(error)
            }
        }
        loadItems()
        loadInventoryTransactions()
    } , [])

    return (
        <main>
            <h1> Inventory Dashboard</h1>
            <div className="dashboardGrid">
                <DashboardPane title="Items">
                    <ItemList items={items}/>
                </DashboardPane>
                <DashboardPane title="Inventory Transactions">
                    <InventoryTransactionList transaction_list={inventoryTransactions}/> 
                </DashboardPane>
            </div>
        </main>
    )
}
export default Dashboard