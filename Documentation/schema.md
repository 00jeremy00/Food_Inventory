# Restaurant Inventory Schema

Table-by-table description of the schema used by the inventory system.

---

## Category
Provides a way to categorize internal inventory items.

### Columns
- **category_name (VARCHAR(64))**: Name of the category (PRIMARY KEY)

---

## Item
Represents internally tracked inventory items.

This table allows the system to aggregate multiple vendor products into a single internal item.  
For example, if a recipe requires 2 quarts of whipping cream, the system may fulfill that using inventory sourced from different vendors, all mapped to the same internal item.

### Columns
- **internal_num (VARCHAR(20))**: Unique identifier for the item (PRIMARY KEY)
- **internal_name (VARCHAR(64))**: Readable name of the item used internally
- **category (VARCHAR(64))**: Category of the item (FOREIGN KEY → Category.category_name)
- **internal_unit (VARCHAR(20))**: Unit of measurement used for internal inventory tracking and transactions

---

## Vendor
Represents companies that supply products to the inventory system.

### Columns
- **vendor_num (VARCHAR(6))**: Unique identifier for the vendor (PRIMARY KEY)
- **vendor_name (VARCHAR(64))**: Name of the vendor
- **phone_number (VARCHAR(20))**: Phone number of the vendor
- **email (VARCHAR(64))**: Email address of the vendor
- **website (VARCHAR(255))**: URL of the vendor's website

---

## Product
Represents vendor-specific products that are used to supply internal inventory items.

This table links vendor products to internal items and defines how purchased quantities are converted into internally tracked units.

### Columns
- **product_num (INT)**: Unique identifier for the product (PRIMARY KEY, AUTO_INCREMENT)
- **vendor_pnum (VARCHAR(64))**: Product identifier used by the vendor
- **vendor_pname (VARCHAR(255))**: Name of the product as defined by the vendor
- **internal_num (VARCHAR(20))**: Internal item associated with the product (FOREIGN KEY → Item.internal_num)
- **purchase_unit (VARCHAR(20))**: Unit in which the product is purchased
- **vendor_num (VARCHAR(6))**: Vendor supplying the product (FOREIGN KEY → Vendor.vendor_num)
- **price (DECIMAL(10,2))**: Price of the product per purchase unit (CHECK strictly positive)
- **conversion_factor (DECIMAL(10,3))**: Factor used to convert purchased units into internal units

Example:  
If a product is purchased as a 200 lb case, then 1 purchase unit × 200 = 200 internal units.

---

## Employee
Represents employees in the system, including managers responsible for approving invoices, transactions, and snapshots.

### Columns
- **employee_num (VARCHAR(20))**: Unique identifier for an employee (PRIMARY KEY)
- **employee_name (VARCHAR(64))**: Name of the employee
- **is_manager (BOOLEAN)**: Indicates whether the employee has manager privileges

---

## Invoice
Stores metadata for invoices submitted by vendors.

### Columns
- **invoice_id (INT)**: Unique internal identifier for the invoice (PRIMARY KEY, AUTO_INCREMENT)
- **invoice_num (VARCHAR(20))**: Identifier assigned to the invoice by the vendor
- **invoice_date (DATE)**: Date the invoice was received or recorded
- **vendor_num (VARCHAR(6))**: Vendor who submitted the invoice (FOREIGN KEY → Vendor.vendor_num)
- **approval_status (ENUM)**: Status of the invoice (`APPROVED`, `PENDING`, `DENIED`), defaults to `PENDING` (CHECK statu in (`APPROVED`, `PENDING`, `DENIED`))
- **approved_by (VARCHAR(20))**: Employee who approved the invoice (FOREIGN KEY → Employee.employee_num); NULL until approved

---

## InvoiceLine
Stores the individual product line items associated with an invoice.

### Columns
- **invoice_id (INT)**: Invoice this line belongs to (FOREIGN KEY → Invoice.invoice_id)
- **product_num (INT)**: Product included on the invoice line (FOREIGN KEY → Product.product_num)
- **quantity (DECIMAL(10,3))**: Quantity of the product ordered
- **line_price (DECIMAL(10,3))**: Total price recorded for this invoice line (CHECK line_price is strictly postive)

### Primary Key
- **(invoice_id, product_num)**: Composite primary key ensuring each product appears at most once per invoice

---
## ProductInventory
Stores the running inventory based on products. Only approved transactions can affect ProductInventory.

### Columns
- **product_num(INT)**: Identifies which product is being counted (PRIMARY KEY, FOREIGN KEY → Product.product_num)
- **quantity(DECIMAL(10,3))**: How much of that product is in the current inventory

---

## Shift
Defines the shifts that can occur on a day.

### Columns
- **shift_name (VARCHAR(20))**: the name of the shift (PRIMARY KEY)
- **start_time (TIME)**: time at which the shift begins
- **end_time (TIME)**: time at which the shift ends

---

## InventoryTransaction
Stores the ledger of all inventory activity.

Every change to inventory is recorded here, including receiving products, usage, waste, and manual adjustments.

### Columns
- **transaction_num (INT)**: Unique identifier for the transaction (PRIMARY KEY, AUTO_INCREMENT)
- **transaction_type (ENUM)**: Type of transaction: `RECEIVE`, `USE`, `WASTE`, `PREP` or `ADJUST` (CHECK transaction_type in (`RECEIVE`, `USE`, `WASTE`, `ADJUST`, `PREP`))
- **quantity (DECIMAL(10,3))**: Quantity associated with the transaction
- **transaction_date (DATETIME)**: Date and time the transaction was created; defaults to the current timestamp
- **approved_by (VARCHAR(20))**: Employee who approved the transaction (FOREIGN KEY → Employee.employee_num)
- **created_by (VARCHAR(20))**: Employee who created the transaction (FOREIGN KEY → Employee.employee_num)
- **approval_status (ENUM)**: Status of the transaction (`APPROVED`, `PENDING`, `DENIED`), defaults to `PENDING`  (CHECK approval_status in (`APPROVED`, `PENDING`, `DENIED`))
- **invoice_id (INT)**: Related invoice if the transaction came from an invoice receipt (FOREIGN KEY → Invoice.invoice_id, nullable)
- **product_num (INT)**: Related product involved in the transaction (FOREIGN KEY → Product.product_num, nullable)
- **batch_num (INT)**: Related batch if it is a `PREP` transaction where the product builds that batch (FOREIGN KEY → Batch.batch_num, nullable)
- **price_per_unit (DECIMAL(10,3))**: Unit price associated with the transaction, if applicable (CHECK price_per_unit is strictly positive)
- **reason (VARCHAR(64))**: Explanation for the transaction, especially useful for waste or manual adjustment cases

### Notes
- 
- `RECEIVE` transactions may reference an invoiceLine and represent the amount of product going up
- `USE` transaction represents using that amount of product
- `WASTE` transactions represent product being wasted, requires reason
- `ADJUST` transactions represent product level being adjusted, requires reason
- `PREP` transactions represent product being used in a specific batch, requires batch_num 

---

## InventorySnapshotRecord
Stores metadata for inventory count snapshots.

A snapshot record represents a counting event, including when it occurred, who managed it, and whether it has been completed.

### Columns
- **snapshot_id (INT)**: Unique identifier for the snapshot record (PRIMARY KEY, AUTO_INCREMENT)
- **snapshot_time (DATETIME)**: Date and time the snapshot was created
- **snapshot_status (ENUM)**: Status of the snapshot record (`PENDING`, `COMPLETED`), defaults to `PENDING` (CHECK snapshot_status IN ('PENDING', 'COMPLETED'))
- **recorded_by (VARCHAR(20))**: Employee responsible for the snapshot (FOREIGN KEY → Employee.employee_num)
- **notes (VARCHAR(255))**: Optional notes about the snapshot

---

## InventorySnapshot
Stores product-level expected and counted quantities for a specific snapshot.

This table is used to compare what the system expected to be on hand for each product against what was physically counted.

### Columns
- **snapshot_id (INT)**: Snapshot record this entry belongs to (FOREIGN KEY → InventorySnapshotRecord.snapshot_id)
- **product_num (INT)**: Product being counted (FOREIGN KEY → Product.product_num)
- **expected_quantity (DECIMAL(10,3))**: Quantity the system expected to be on hand (CHECK expected_quantity not negative)
- **counted_quantity (DECIMAL(10,3))**: Quantity physically counted during the snapshot (CHECK counted_quantity not negative)

### Primary Key
- **(snapshot_id, product_num)**: Composite primary key ensuring one record per product per snapshot

---


## Recipe
Describes possible recipes that can be made. 

### Columns
- **recipe_num(INT)**: Unique identifier for recipe (PRIMARY KEY, AUTO_INCREMENT)
- **recipe_name(VARCHAR(64))**: Name of the recipe
- **recipe_status(ENUM)**: status of recipe either `PENDING`, `ACTIVE`, or `INACTIVE`
- **shelf_life(INT)**: Number of hours that a recipe is good for
- **recipe_unit (VARCHAR(20))**: The unit in which the recipe is changed
- **yield DECIMAL(10,3)**: Amount of food that recipe creates in recipe_unit

---

### Notes
- `PENDING` status means that ingredients are still being allocated to recipe. recipe must be `PENDING` to add ingredients
- `ACTIVE` status means that the recipe is being used
- `INACTIVE` status means that the recipe is not longer being used

## Ingredient
Lists the ingredients that contribute to a recipe to keep track of recipe usage.

### Columns
- **recipe_num(INT)**: identifies which recipe this ingredient is for
- **internal_num(VARCHAR(20))**: the ingredient that the recipe is refering to
- **quantity(DECIMAL(10,3))**: quantity of ingredient used in the recipe

### Primary Key
- **(recipe_num, internal_num)**: Composite primary key ensuring no more than one item can be assigned to a recipe 
---


## PrepPlan
Stores planned recipe production for a given date.

Prep plans represent expected recipe usage and are used to estimate future inventory needs. It does not directly affect Inventory, but are used to calculate projections and store prep plans to learn/replicate.

### Columns
- **plan_num (INT)**: Unique identifier for the prep plan (PRIMARY KEY, AUTO_INCREMENT)
- **recipe_num (INT)**: Recipe to be prepared (FOREIGN KEY → Recipe.recipe_num)
- **plan_date (DATE)**: Date the recipe is planned to be made
- **quantity (DECIMAL(10,3))**: Number of times the recipe is planned to be made
- **shift_name (VARCHAR(20))**: The shift which is responsible for executing the plan, NULL if any shift can do it (FOREIGN KEY → Shift.shift_name)
- **plan_status (ENUM)**: status of the plan: `PENDING` when it has not been completed or `COMPLETED` when done
 - **planned_by (VARCHAR(20))**: who planned the prep (FOREIGN KEY → Employee.employee_num)
---

## Batch
Describes recipes that have been created

### Columns
- **batch_num(INT)**: Unique identifier of the batch (PRIMARY KEY, AUTO_INCREMENT)
- **recipe_num(INT)**: The batch makes this recipe (FOREIGN KEY → Recipe.recipe_num)
- **created_on(DATETIME)**: The datetime which it was created
- **created_by VARCHAR(20)**: Employee who created the batch
- **quantity_prepared(DECIMAL(10,3))**: The amount of recipe that was prepared in the units of the recipe
- **quantity_remaining(DECIMAL(10,3))**: The amount of recipe remaining, describes the amount expired if status is expired.
- **expires_at(DATETIME)**: Time at which the recipe expires
- **plan_num (INT)**: The plan that was followed to create this batch, NULL if unplanned (FOREIGN KEY → PrepPlan.plan_num)
- **batch_status(ENUM)**: Describes the status of the batch (`PENDING`,`ACTIVE`,`DEPLETED`,`EXPIRED`) deafults to `PENDING` meaning it is waiting product allocation. `ACTIVE` means it is ready for use. `DEPLETED` means that the recipe has been totally used. `EXPIRED` means that some or all of the product was expired.

--- 

## BatchTransaction
Stores a ledger of all batch-level transactions

Every change in batch level is stored here, including using, wasting, creating, and expiring

### Columns
- **transaction_num (INT)**: Unqiue identifier for batch transaction (PRIMARY KEY, AUTO_INCREMENT)
- **batch_num(INT)**: Refers to the batch which the transaction is affecting (FOREIGN KEY → Batch.batch_num)
- **transaction_type (ENUM)**: Describes the type of transaction, either `CREATE`, `USE`, `ADJUST`, `WASTE`, `EXPIRE`, 
- **quantity (DECIMAL(10,3))**: the quantity of the batch that is being affected recorded in units from Recipe
- **created_by (VARCHAR(20))**: the employee who created transaction
- **transaction_date (DATETIME)**: the datetime which the transaction was created
- **reason (VARCHAR(64))**: reason for the transaction, required for `WASTE` and `ADJUST`

### Notes
- `CREATE` occurs when a batch is activated
- `USE` represents consumption of prepared inventory
- `WASTE` represents discarded prepared inventory
- `EXPIRE` represents unused quantity at expiration
- `ADJUST` represents manager correcting batch levels


## Relationship Summary

- Each **Item** belongs to one **Category**
- Each **Product** belongs to one **Vendor**
- Multiple **Products** may map to a single **Item**
- Each **Invoice** belongs to one **Vendor**
- Each **InvoiceLine** belongs to one **Invoice** and one **Product**
- Each **ProductInventory** record corresponds to one **Product**
- Each **InventoryTransaction** affects one **ProductInventory**
- Each **InventoryTransaction** is created and approved by one **Employee**
- **InventoryTransaction** may reference one **Batch** for `PREP` transactions
- **InventoryTransaction** may reference one **Invoice** for `RECEIVE` transactions
- Each **InventorySnapshotRecord** is recorded by one **Employee**
- Each **InventorySnapshot** stores product-level counts for one snapshot
- Each **Recipe** may have multiple **Ingredient** which make it
- Each **Batch** contains a **Recipe**
- Each **Batch** is created by one **Employee**
- Each **BatchTransaction** affects one **Batch**
- Each **BatchTransaction** is created by one **Employee**

