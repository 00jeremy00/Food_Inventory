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

## Inventory
Stores the current on-hand quantity of each internal item.

### Columns
- **internal_num (VARCHAR(20))**: Internal item identifier (PRIMARY KEY, FOREIGN KEY → Item.internal_num)
- **quantity (DECIMAL(10,3))**: Current quantity available; defaults to 0.0 (CHECK quantity is 0 or greater)

This table represents the current inventory state, while `InventoryTransaction` stores the history of inventory changes.

---

## InventoryTransaction
Stores the ledger of all inventory activity.

Every change to inventory is recorded here, including receiving products, usage, waste, and manual adjustments.

### Columns
- **transaction_num (INT)**: Unique identifier for the transaction (PRIMARY KEY, AUTO_INCREMENT)
- **internal_num (VARCHAR(20))**: Internal item affected by the transaction (FOREIGN KEY → Item.internal_num)
- **transaction_type (ENUM)**: Type of transaction: `RECEIVE`, `USE`, `WASTE`, or `ADJUST` (CHECK transaction_type in (`RECEIVE`, `USE`, `WASTE`, `ADJUST`))
- **quantity (DECIMAL(10,3))**: Quantity associated with the transaction
- **transaction_date (DATETIME)**: Date and time the transaction was created; defaults to the current timestamp
- **approved_by (VARCHAR(20))**: Employee who approved the transaction (FOREIGN KEY → Employee.employee_num)
- **created_by (VARCHAR(20))**: Employee who created the transaction (FOREIGN KEY → Employee.employee_num)
- **approval_status (ENUM)**: Status of the transaction (`APPROVED`, `PENDING`, `DENIED`), defaults to `PENDING`  (CHECK approval_status in (`APPROVED`, `PENDING`, `DENIED`))
- **invoice_id (INT)**: Related invoice if the transaction came from an invoice receipt (FOREIGN KEY → Invoice.invoice_id, nullable)
- **product_num (INT)**: Related product involved in the transaction (FOREIGN KEY → Product.product_num, nullable)
- **price_per_unit (DECIMAL(10,3))**: Unit price associated with the transaction, if applicable (CHECK price_per_unit is strictly positive)
- **reason (VARCHAR(64))**: Explanation for the transaction, especially useful for waste or manual adjustment cases

### Notes
- `RECEIVE` transactions may reference an invoice and product
- `USE`, `WASTE`, and `ADJUST` transactions may not require an invoice

---

## InventorySnapshotRecord
Stores metadata for inventory count snapshots.

A snapshot record represents a counting event, including when it occurred, who managed it, and whether it has been completed.

### Columns
- **snapshot_id (INT)**: Unique identifier for the snapshot record (PRIMARY KEY, AUTO_INCREMENT)
- **snapshot_time (DATETIME)**: Date and time the snapshot was created
- **previous_snapshot (INT)**: Identifier of the previous snapshot, if applicable
- **snapshot_status (ENUM)**: Status of the snapshot record (`PENDING`, `COMPLETED`), defaults to `PENDING` (CHECK snapshot_status IN ('PENDING', 'COMPLETED'))
- **manager_num (VARCHAR(20))**: Employee responsible for the snapshot (FOREIGN KEY → Employee.employee_num)
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

## ItemVariance
Stores item-level expected and counted quantities for a specific snapshot.

This table aggregates variance at the internal item level, allowing comparison across all vendor products that map to the same internal item.

### Columns
- **snapshot_id (INT)**: Snapshot record this entry belongs to (FOREIGN KEY → InventorySnapshotRecord.snapshot_id)
- **internal_num (VARCHAR(20))**: Internal item being evaluated (FOREIGN KEY → Item.internal_num)
- **expected_quantity (DECIMAL(10,3))**: Expected quantity for the item (CHECK expected_quantity not negative)
- **counted_quantity (DECIMAL(10,3))**: Counted quantity for the item (CHECK counted_quantity not negative)

### Primary Key
- **(snapshot_id, internal_num)**: Composite primary key ensuring one variance record per item per snapshot

---


## Recipe
Describes possible recipes that can be made. 

### Columns
- **recipe_num(INT)**: Unique identifier for recipe (PRIMARY KEY, AUTO_INCREMENT)
- **recipe_name(VARCHAR(64))**: Name of the recipe
- **is_active(BOOLEAN)**: True if active recipe otherwie False

---

## Ingredient
Lists the ingredients that contribute to a recipe to keep track of recipe usage.

### Columns
- **recipe_num(INT)**: identifies which recipe this ingredient is for
- **internal_num(VARCHAR(20))**: the ingredient that the recipe is refering to
- **quantity(DECIMAL(10,3))**: quantity of ingredient used in the recipe

### Primary Key
- **(recipe_num, internal_num)**: Composite primary key ensuring no more than one item can be assigned to a recipe 
---

## Relationship Summary

- Each **Item** belongs to one **Category**
- Each **Product** belongs to one **Vendor**
- Multiple **Products** may map to a single **Item**
- Each **Invoice** belongs to one **Vendor**
- Each **InvoiceLine** belongs to one **Invoice** and one **Product**
- Each **Inventory** record corresponds to one **Item**
- Each **InventoryTransaction** affects one **Item**
- Each **InventorySnapshotRecord** is managed by one **Employee**
- Each **InventorySnapshot** stores product-level counts for one snapshot
- Each **ItemVariance** stores item-level counts for one snapshot

---
# ER Diagram Code
Code to ER Diagram for dbdiagram.io
Table Category {
  category_name varchar(64) [pk]
}

Table Item {
  internal_num varchar(20) [pk]
  internal_name varchar(64) [not null]
  category varchar(64) [not null]
  internal_unit varchar(20) [not null]
}

Table Vendor {
  vendor_num varchar(6) [pk]
  vendor_name varchar(64) [not null]
  phone_number varchar(20)
  email varchar(64)
  website varchar(255)
}

Table Product {
  product_num int [pk, increment]
  vendor_pnum varchar(64) [not null]
  vendor_pname varchar(255) [not null]
  internal_num varchar(20) [not null]
  purchase_unit varchar(20) [not null]
  vendor_num varchar(6) [not null]
  price decimal(10,2) [not null]
  conversion_factor decimal(10,3) [not null]
}

Table Employee {
  employee_num varchar(20) [pk]
  employee_name varchar(64) [not null]
  is_manager boolean [not null]
}

Table Invoice {
  invoice_id int [pk, increment]
  invoice_num varchar(20) [not null]
  invoice_date date [not null]
  vendor_num varchar(6) [not null]
  approval_status enum('APPROVED', 'PENDING', 'DENIED') [not null, default: 'PENDING']
  approved_by varchar(20)
}

Table InvoiceLine {
  invoice_id int [pk]
  product_num int [pk]
  quantity decimal(10,3) [not null]
  line_price decimal(10,3) [not null]
}

Table Inventory {
  internal_num varchar(20) [pk]
  quantity decimal(10,3) [not null, default: 0.0]
}

Table InventoryTransaction {
  transaction_num int [pk, increment]
  internal_num varchar(20) [not null]
  transaction_type enum('RECEIVE', 'USE', 'WASTE', 'ADJUST') [not null]
  quantity decimal(10,3) [not null]
  transaction_date datetime [not null, default: `CURRENT_TIMESTAMP`]
  approved_by varchar(20)
  created_by varchar(20)
  approval_status enum('APPROVED', 'PENDING', 'DENIED') [not null, default: 'PENDING']
  invoice_id int
  product_num int
  price_per_unit decimal(10,3)
  reason varchar(64)
}

Table InventorySnapshotRecord {
  snapshot_id int [pk, increment]
  snapshot_time datetime [not null]
  previous_snapshot int
  snapshot_status enum('PENDING', 'COMPLETED') [not null, default: 'PENDING']
  manager_num varchar(20) [not null]
  notes varchar(255)
}

Table InventorySnapshot {
  snapshot_id int [pk]
  product_num int [pk]
  expected_quantity decimal(10,3) [not null]
  counted_quantity decimal(10,3) [not null]
}

Table ItemVariance {
  snapshot_id int [pk]
  internal_num varchar(20) [pk]
  expected_quantity decimal(10,3) [not null]
  counted_quantity decimal(10,3) [not null]
}

Ref: Item.category > Category.category_name
Ref: Product.vendor_num > Vendor.vendor_num
Ref: Product.internal_num > Item.internal_num
Ref: Invoice.vendor_num > Vendor.vendor_num
Ref: Invoice.approved_by > Employee.employee_num
Ref: InvoiceLine.invoice_id > Invoice.invoice_id
Ref: InvoiceLine.product_num > Product.product_num
Ref: Inventory.internal_num > Item.internal_num
Ref: InventoryTransaction.product_num > Product.product_num
Ref: InventoryTransaction.invoice_id > Invoice.invoice_id
Ref: InventoryTransaction.internal_num > Item.internal_num
Ref: InventoryTransaction.approved_by > Employee.employee_num
Ref: InventoryTransaction.created_by > Employee.employee_num
Ref: InventorySnapshotRecord.manager_num > Employee.employee_num
Ref: InventorySnapshot.product_num > Product.product_num
Ref: InventorySnapshot.snapshot_id > InventorySnapshotRecord.snapshot_id
Ref: ItemVariance.snapshot_id > InventorySnapshotRecord.snapshot_id
Ref: ItemVariance.internal_num > Item.internal_num 