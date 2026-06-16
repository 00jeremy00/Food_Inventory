import {API_URL} from "./config"

export async function apiGet<T>(path: string, params?: Record<string, any>): Promise<T> {
    const url = new URL(`${API_URL}${path}`)

    if (params) {
        Object.keys(params).forEach(key => url.searchParams.append(key, String(params[key])))
    }
    console.log(`Fetching from API: ${url.toString()}`)
    const response = await fetch(`${API_URL}${path}`)

    if (!response.ok) {
        throw new Error(`API request failed with status ${response.status}`)
    }

    return response.json()
}