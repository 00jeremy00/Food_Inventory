const API_URL = "http://127.0.0.1:8000"

export async function fetchProducts(){
    const response = await fetch(`${API_URL}/products/`)

    if (!response.ok){
        throw new Error("Failed to fetch products")
    }

    return response.json()
}