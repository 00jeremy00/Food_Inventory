# Stored Procedures for Restaurant Inventory System

These proceudres are the primary way that the database should be interacted with. They all enforce buiness rules and enure data integrity.

# Procedures

## resolveInvoice
Finalizes a pending invoice by changing its status to APPROVED or DENIED and passes that finalization down to the corresponding InventoryTransactions related to the invoice, and if the invoice is being approved, updates inventory levels. Given that the invoice is approved, it will also update price in product to keep prices current.

## Input Parameters
1. invoice_id: identifier of the invoice that is being resolved
2. approval_status: resolution status we are setting the invoice to, either APPROVED or DENIED
3. approved_by: employee num of the manager who approved the invoice

### Goals
- Ensures invoice_id is valid.
- Validates that invoice has not already been finalized
- Validate that the employee number for approval is a valid employee with manager status
- Validate that the final state is either APPROVED or DENIED
- Verify that the transactions associated with the invoice_id have valid product numbers associated with the invoice's vendor.
- Update price in product table if invoice is approved
- Update the inventory number associated with that product if invoice is approved
- Update inventory transaction status
- Update invoice status

---

## resolveInventoryTransaction
Finalizes inventory transaction and update Inventory levels associated with that item given the statuss is being updated to APPROVED. Note that all RECEIVE transactions must be processed by resolving the invoice.

### Input Parameters
1. transaction_num: transaction number that is being resolved
2. new_status: finalized transaction status either APPROVED or DENIED
3. p_approved_by: employee number of who approved the resolution, employee must be manager

### Goals
- Validate transaction_num is associated with a valid transaction in PENDING status
- Lock inventory transaction selected for update
- Validate that new_status is either APPROVED or DENIED
- Validate approved_by is a valid employee number with manager status
- Verify that transaction type is valid and not RECEIVE 
- Validate product number associated with transaction
- Validate that transaction was created by valid employee
- Verify that employee num for approved_by is valid and is a manager
- Verify that transaction quantity is not negative unless transaction_type is ADJUST
- Evaluate the inventory after the transaction takes place and ensure that it is valid
- Update inventory with the update quantity
- Update status of the transaction

---

## createUseTransaction
Creates an inventory transaction of USE type, recording the product used, quantity, and creator.

### Input Parameters
1. use_product: product number being used
2. use_quantity: quantity of product being used in internal units
3. creator: employee number of the creator of the transaction

### Goals
- Verify that creator is a valid employee
- Verify that use_quantity is positive
- Verify item's product number is valid
- Verify that product number is valid and matched internal item
- Verify that the price and conversion_factor for the product is postive
- Converts price per product unit to price per internal unit
- Insert into InventoryTransaction

---

## createAdjustTransaction
Creates an inventory transaction of ADJUST type, recording product, quantity, creator of the transaction, reason for adjustment and product number which may be NULL if unknown.

### Input Parameters
1. adjust_product: product number for item that is being used
2. trans_quantity: quantity of item being used in internal units
3. creator: employee number of the creator of the transaction
4. use_product_num: the product number of the used product, if unknown NULL
5. adjust_reason reason/explanation for the transaction

### Goals
- Ensure that quantity for transaction is not valid, can be positive or negative only
- Verify that the creator of the transaction is a valid employee
- Ensure that a reason is supplied for the inventory adjustment
- Verify that the product number for the adjustment is valid
- Validate the product's price per order unit and conversion factor
- Sets transaction price in terms of internal units
- Inserts into InventoryTransaction

---

## createWasteTransaction
Creates an inventory transaction of WASTE type, recording product number, quantity, creator of the transaction, reason for adjustment and product number which may be NULL if unknown.
### Input Parameters
1. waste_product: product number for item that is being used
2. trans_quantity: quantity of item being used in internal units
3. creator: employee number of the creator of the transaction
4. waste_product_num: the product number of the used product, if unknown NULL
5. waste_reason: reason/explanation for the transaction

# Goals
- Verify trans_quantity is strictly positive
- Verifies product num is a valid product
- Ensures that a reason was given for waste transactin
- Verfies that a valid employee number was given to create the transaction
- Validates products price and conversion factor and converts price to internal units
- Inserts into InventoryTransaction

---

## addItem
Adds an internal item into the Item table.

### Input Parameters
1. new_id: internal_num for the new item
2. new_name: name of the inserted item
3. new_category: the category that the item is
4. new_unit: internal_unit which the item is counted in(this is also the unit for Inventory and InventoryTransaction)

### Goals
- Verify that new_id is valid and that another item does not already use that value
- Verify that name is supplied
- Verify that you the category is valid and in Category table
- Verify that the new_unit is not NULL or empty
- Insert into Item

---

## addProduct
Inserts new product into the product table.

### Input Parameters
1. new_product: product number given from vendor
2. new_name: name of product from vendor
3. new_internal_num: internal item associated with the product
4. new_unit: unit in which the product is orderd
5. new_vendor: vendor who supplies the product
6. new_price: price to order one product in the order units
7. new_factor: conversion factor that converts product units to internal units
    given units in order unit(located in product) multiply with factor to get internal unit

### Goals
- Verify that vendor is valid
- Verify that product_num is a valid string
- Verify that there is no duplicate product number from the same vendor
- Verify that new internal number is valid
- Verify that product name is a valid string
- Verify that unit is a valid string
- Verify new_factor is not NULL and strictly positive
- Veirfy that new_price is strictly positve and not NULL
- Inesrt into Product

---

## addVnedor
Inserts vendor into vendor table.

### Input Parameters
1. new_vendor_num: identifier of new vendor
2. new_name: name for new vendor
3. new_phone_number: phone number for new vendor
4. new_email: email for new vendor
5. new_webite: URL for new vendor

### Goals
- Verify that new_vendor_num is a non-empty, non-NULL string that is not taken
- Verify that new_name is a valid string
- Insert into new vendor into Vendor table

---

## addEmployee
Inserts employee into employee  table

### Input Parameters
1. new_employee_num: employee num of new employee
2. new_name: name of new employee
3. manager_status: Boolean variable, TRUE if manager, otherwise FALSE

### Goals
- Verify new_employee_num is a valid string and is not taken by another employee
- Verify that new_name is a valid string
- Verify manager_status is not NULL
- Insert new employee into Employee table

---

## addInvoice
Inserts an invoice into the Invoice table

### Input Parameters
1. new_invoice: invoice number
2. new_date: date the invoice came in
3. new_vendor: vendor who sent the invoice

### Goals
- Verifies new_vendor represents a valid vendor
- Verifies new_invoice is a valid string and that there is no invoice from new_vendor with the same invoice number
- Verify that new_date is valid
- Insert new invoice into Invoice table

---

## addInvoiceLine
Adds record in InvoiceLine table which describes products that are received from an vendor associated by an invoice.

### Input Parameters
1. new_invoice: invoice id for line item
2. new_product_num: product number of the product being received
3. new_quantity: amount of product being received in order units
4. new_line_price: total price for new_quantity number of products
5. creator: employee number of a manager who is entering the invoice

### Goals
- Ensure invoice_id is valid
- Ensure that the associated invoice has not already been APPROVED or DENIED
- Validate manager creator credentials
- Validate that product_num is associated with a valid product
- Verify that quantity incoming is strictly positive
- Verify that the vendor associated with the invoice sells the product
- Select necceary information from product to convert new_quantity to internal units
- Convert total price to price per internal unit
- Start transaction before inserts so either both occur or neither
- Perform insertion into InvoiceLine with price and quantity in terms of initial input
- Insert into InventoryTransaction with price and quantity in terms of internal units

---

## addRecipe
Creates a recipe which ingredients can reference.

### Input Parameters
1. new_recipe_name: name of the new recipe
2. new_active: True if new recipe is active otherwise false

### Goals
- Verify that new_recipe_name is a valid string
- Verify that new_active is not NULL
- Insert into Recipe

---

## addIngredient
Creates one ingredient that will be used in a recipe.

### Input Parameters
1. new_item: item which the ingredient calls for
2. ingredient_recipe: recipe which this ingredient contributes to
3. new_quantity: the amount of ingredient the recipe calls for in internal units

### Goals
- Verify ingredient_recipe is valid and refers to a recipe that exists and is active
- Verify that new_item string is valid and refers to an item
- Verify that new_quantity is strictly positive
- Insert into Ingredient

## createInventorySnapshotRecord
Creates an inventory snapsshot record which will have snapshots which count the products for that record refering to it.

### Input Parameters
1. recorder: employee number of who is creating the snapshot and counting the inventory, must be a manager
### Goals
- Verifies recorder is a valid manager
- Insert into InventorySnapshotRecord with the CURRENT_TIMESTAMP and PENDING status


## createInventorySnapshot
Creates the Inventory Snapshot recording for one product which includes its expected amount and the amount physically counted

### Input Parameters
1. inventory_snapshot: the snapsphot record which this snapshot refers to
2. inventory_product:the product number of the product which is being counted
3. counted_total: how much the the product was physically counted.

### Goals
- Verify inventory_snapshot refers to a valid snapshot
- Verify inventory_product refers to a valid product
- Verify counted_total is valid and not negative
- Verify ProductInventory has a valid quantity and store for expected_quantity
- Insert snapshot info into InventorySnapshot

## completeSnapshot
Completes an inventory snapshot by updating record and verifying that all products with non-zero ProductInventory quantities have snapshots recording inventory.

### Input Parameters
1. completed_snapshot: refers to the snapshot record which needs to be resolved
### Goals
- Verify that snapshot is valid
- Verify that the snapshot's status is PENDING
- For each ProductInventory with a nonzero quantity
- Update snapshot_status in InventorySnapshotRecord to COMPLETED
