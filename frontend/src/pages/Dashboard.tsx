import { useEffect, useState } from "react"
import DashboardPane from "../components/layout/dashboardPane"

import { fetchInventoryTransactions } from "../api/inventoryTransactionsApi"
import { fetchItems } from "../api/itemsApi"
import { fetchBatches } from "../api/batchApi"

import type {Item} from "../types/items"
import type { InventoryTransaction } from "../types/inventoryTransaction"
import type { Batch } from "../types/batches"

import InventoryTransactionList from "../components/inventory_transactions/inventoryTransactionList"
import ItemList  from "../components/items/itemList"
import BatchList from "../components/batches/batchList"

import "../styles/dashboard.css"

function Dashboard(){
    const [items, setItems] = useState<Item[]>([])
    const [inventoryTransactions, setInventoryTransactions] = useState<InventoryTransaction[]>([])
    const [batches, setBatches] = useState<Batch[]>([])

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

        async function loadActiveBatches() {
            try {
                const data = await fetchBatches({status: 'ACTIVE'})
                setBatches(data)
            } catch (error) {
                console.error(error)
            }
        }

        loadItems()
        loadInventoryTransactions()
        loadActiveBatches()
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
                <DashboardPane  title="Batches">
                    <BatchList batches={batches}/>
                </DashboardPane>
            </div>
            <ul>
                <li>a</li>
                <li>b</li>
                <li>c</li> 
                <li>a</li>
                <li>b</li>
                <li>c</li> 
                <li>a</li>
                <li>b</li>
                <li>c</li> 
            </ul>
        </main>
    )
}
export default Dashboard