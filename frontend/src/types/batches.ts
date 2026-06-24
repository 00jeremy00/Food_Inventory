import type { BatchStatus } from "./enums"

export type Batch = {
    batch_num: number
    recipe_num: number
    recipe_name: string
    created_on: string
    created_by: string
    created_by_name: string
    approved_by: string | null
    approved_by_name: string | null
    plan_num: number | null
    prepared_quantity: string
    remaining_quantity:  string
    recipe_unit: string
    depleted_at: string | null
    expires_at: string  | null
    batch_status: BatchStatus
    par: string
}
