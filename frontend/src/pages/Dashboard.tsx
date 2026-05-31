import { useEffect, useState } from "react"
import { fetchItems } from "../api/itemsApi"
import ItemList  from "../components/items/itemList"
import DashboardPane from "../components/layout/dashboardPane"

import type {Item} from "../types/items"

function Dashboard(){
    const [items, setItems] = useState<Item[]>([])

    useEffect(() => {
        async function loadItems(){
            try {
                const data = await fetchItems()
                setItems(data)
            }
            catch (error){
                console.error(ErrorEvent)
            }
        }
        loadItems()
    } , [])

    return (
        <main>
            <h1> Inventory Dashboard</h1>
                <DashboardPane title="Items">
                    <ItemList items={items}/>
                </DashboardPane>
        </main>
    )
}
export default Dashboard