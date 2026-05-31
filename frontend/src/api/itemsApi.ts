import {API_URL} from "./config"

export async function fetchItems(){
    const response = await fetch(`${API_URL}/items/`)

    if (!response.ok){
        throw new Error("Failed to fetch items")
    }

    return response.json()
}