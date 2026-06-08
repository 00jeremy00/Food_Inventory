import {API_URL} from"./config"

export async function fetch_batches(){
    const response = await fetch(`${API_URL}/batches/`)
    if(!response.ok){
        throw new Error('Batches could not be fetched')
    }
    return response.json()
}
 