import { apiGet } from "./apiClient"   
import type { InventoryTransaction } from "../types/inventoryTransaction"

export function fetchInventoryTransactions() {
    return apiGet<InventoryTransaction[]>("/inventory-transactions/")
}