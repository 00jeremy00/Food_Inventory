export type ApprovalStatus =
    | "PENDING"
    | "APPROVED"
    | "DENIED"

export type InventoryTransactionType = 
    | "RECEIVE"
    | "USE"
    | "WASTE"
    | "ADJUST"
    | "PREP"

export type BatchStatus = 
    | "PENIDNG"
    | "ACTIVE"
    | "DEPLETED"
    | "EXPIRED"