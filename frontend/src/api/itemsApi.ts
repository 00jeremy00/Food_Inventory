import { apiGet } from "./apiClient"   
import type { Item } from "../types/items"

export function fetchItems() {
    return apiGet<Item[]>("/items/")
}