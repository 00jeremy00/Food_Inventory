import { apiGet } from "./apiClient"   
import type { Batch } from "../types/batches"

type BatchFilters = {
    status?: string
}

export function fetchBatches(filters?: BatchFilters) {
    return apiGet<Batch[]>("/batches/", filters)
}