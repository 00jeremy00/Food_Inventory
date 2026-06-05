import {API_URL} from "./config"

export async function fetchInventoryTransactions(){
    const response = await fetch(`${API_URL}/inventory-transactions/`)
    if(!response.ok){
        throw new Error('Inventory Transactions could not be fetched')
    }
    return response.json()
}
