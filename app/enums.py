from enum import Enum

class ApprovalStatus(str, Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    DENIED = "DENIED"

class InventoryTransactionType(str, Enum):
    RECEIVE = "RECEIVE"
    USE ="USE"
    WASTE = "WASTE"
    ADJUST = "ADJUST"
    PREP = "PREP"

class BatchStatus(str, Enum):
    PENDING = "PENDING"
    ACTIVE = "ACTIVE"
    DEPLETED = "DEPLETED"
    EXPIRED = "EXPIRED"

class BatchTransactionType(str, Enum):
    CREATE = "CREATE"
    USE = "USE"
    ADJUST = "ADJUST"
    WASTE = "WASTE"
    EXPIRE = "EXPIRE"

class SnapshotStatus(str, Enum):
    COMPLETED = "COMPLETED"
    PENDING = "PENDING"

class RecipeStatus(str, Enum):
    PENDING = "PENDING"
    INACTIVE = "INACTIVE"
    ACTIVE = "ACTIVE"

class PlanStatus(str, Enum):
    PENDING = "PENDING"
    COMPLETED = "COMPLETED"

