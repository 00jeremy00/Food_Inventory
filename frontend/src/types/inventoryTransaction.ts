import type { ApprovalStatus, InventoryTransactionType  } from "./enums"

export type InventoryTransaction = {
    transaction_num: number
    transaction_type: InventoryTransactionType
    quantity: string
    internal_units: string
    transaction_date: string
    approved_by: string | null
    approver_name: string | null
    created_by: string
    creator_name: string
    approval_status: ApprovalStatus
    invoice_id: number |null
    product_num: number
    price_per_unit: string
    batch_num: number | null
    reason: string | null
}