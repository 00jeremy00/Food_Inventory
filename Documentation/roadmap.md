## Project Roadmap

### Phase 1 — Core Schema (DONE)
- Category, Item, Vendor
- Product (with conversion_factor)
- ProductInventory
- InventoryTransaction
- Employee (with is_manager)

---

### Phase 2 — Recipe System (DONE)
- Recipe table (status, yield, unit)
- Ingredient table
- Recipe procedures
- Validation rules

---

### Phase 3 — Transaction & Approval System (DONE)
- InventoryTransaction procedures (USE, WASTE, ADJUST, RECEIVE)
- Approval workflow (PENDING → APPROVED / DENIED)
- Business logic moved to stored procedures
- Transactions + locking (START TRANSACTION, FOR UPDATE, rollback)

---

### Phase 4 — Batch / Prep System (DONE)
- Batch table
- PrepPlan table
- PREP transactions
- Allocation validation (Ingredient ↔ PREP transactions)
- activateBatch procedure
- Inventory deduction on activation

---

### Phase 5 — Snapshot / Analytics Layer (DONE)
Tables:
- InventorySnapshot
- ProductSnapshot
- RecipeSnapshot

Procedures:
- createInventorySnapshot
- createRecipeSnapshot

Purpose:
- store expected vs counted quantities
- enable variance analysis and historical tracking

---

### Phase 6 — FastAPI Backend
- endpoints for transactions, batches, snapshots
- call stored procedures from API
- return validation errors cleanly

---

### Phase 7 — React Frontend
- dasboard allows users to view status of database
- allows intuitive manipulation of database for users

### Phase 8 — ML / Forecasting
- demand prediction
- prep optimization
- purchasing suggestions
