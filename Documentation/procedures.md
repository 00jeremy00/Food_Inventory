# Stored Procedures for Restaurant Inventory System

These proceudres are the primary way that the database should be interacted with. They all enforce buiness rules and enure data integrity.

# Core Procedures


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

## addVendor
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

# Invoice Procedures


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


## resolveInvoice
Finalizes a pending invoice by changing its status to APPROVED or DENIED and passes that finalization down to the corresponding InventoryTransactions related to the invoice, and if the invoice is being approved, updates inventory levels. Given that the invoice is approved, it will also update price in product to keep prices current.

### Input Parameters
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

# Inventory Transaction Procedures

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
- Verify that transaction type is valid and not RECEIVE  or PREP
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

### Goals
- Verify trans_quantity is strictly positive
- Verifies product num is a valid product
- Ensures that a reason was given for waste transactin
- Verfies that a valid employee number was given to create the transaction
- Validates products price and conversion factor and converts price to internal units
- Inserts into InventoryTransaction

---



# Recipe Procedures
## addRecipe
Creates a recipe which ingredients can reference.

### Input Parameters
1. new_recipe_name: name of the new recipe
2. new_active: True if new recipe is active otherwise false
3. new_shelflife_hour: number of hours before the recipe expires 
4. recipe_yeild: amount of of the recipe is yeilded in recipe unites
5. new_unit: quantity that the recipe is measure in

### Goals
- Verify that new_recipe_name is a valid string
- Verify that new_active is not NULL
- Verify new_shelflife_hour is not NULL and is strictly positive
- Verify that recipe_yield is not NULL and strictly positive
- Verify that new_unit is not NULL
- Insert into Recipe with recipe status as `PENDING`

---

## addIngredient
Creates one ingredient that will be used in a recipe.

### Input Parameters
1. new_item: item which the ingredient calls for
2. ingredient_recipe: recipe which this ingredient contributes to
3. new_quantity: the amount of ingredient the recipe calls for in internal units

### Goals
- Verify ingredient_recipe is valid and refers to a recipe that exists and is pending
- Verify that new_item string is valid and refers to an item
- Verify that new_quantity is strictly positive
- Insert into Ingredient
---

## createPrepPlan
Creates a prep plan for producing a quantity of a recipe on a given date and shift.

### Input Parameters
1. **new_plan_recipe INT**: the recipe which the plan is calling to make
2. **new_plan_date DATE**: The date which the recipe should be prepared
3. **new_quantity DECIMAL(10,3)**: The quantity of recipe that should be prepared
4. **new_plan_shift VARCHAR(20)**: Shift which is responsible for executing the plan
5. **new_planner VARCHAR(20)**: The emplyee who made the plan

### Verifies
- **new_plan_recipe** is not NULL and refers to a valid recipe that is active
- **new_plan_date** is not NULL and has date of today or after
- **new_quantity** is not NULL and strictly positive
- **new_plan_shift** is either null, empty string or refers to a valid shift
- **new_planner** is not NULL or empty string and refers to a valid employee

### Behavior
- Inserts PENDING prep plan into PrepPlan table
---

## createUnplannedBatch
Creates a batch, which refers to a quantity of recipes prepared on a certain time by a certain person, giving the ability to track usage and ensure batch is wasted at expiraton

Creates a batch that is not associated with a prep plan.

### Input Parameters
1. **batch_recipe INT**: refers to the recipe which the batch prepared
2. **recipe_quantity DECIMAL(10,3)**: The quantity of recipe which was created in that batch
3. **batch_creator VARCHAR(20)**: The employee who prepared the batch

### Verifies
- Make sure that **batch_recipe** is not NULL and refers to an active recipe
- Make sure that **recipe_quantity** is not NULL and is strictly positive
- **batch_creator** is not NULL and refers to a valid employee

### Behavior
- Inserts a pending batch which was not based on a prep plan awaiting allocation

---

## executePrepPlan
Takes the number corresponding to a prep plan and converts the plan into a batch awaiting product allocationt to finalize.

### Input Parameters
1. **plan_execute INT**: the plan in PrepPlan which we are executing
2. **batch_creator VARCHAR(20)**: the employee who will be creating the batch

### Verifies
- Verify **plan_execute** is not NULL and refers to a valid plan
- Verify **batch_creator** is not NULL, not an empty string, and refers to a valid employee
- Verify that recipe assocated with **plan_num** is not NULL and refers to an active recipe
- Verify that the date associated with **plan_num** is not NULL and is the day of batch creation, today
- Verify that the quantity associated with **plan_num** is not NULL and strictly positive
- Verify that shift assocated with **plan_num** is either NULL or refers to a valid shift
- Given shift is not NULL, ensure that the current time is within the shift time interval
- Verify that the plan was in a `PENDING` status
- Verify that there is not already a batch derrived from PrepPlan

### Behavior
- Pull all required batch information from PrepPlan
- Insert new batch into Batch table

---





## createPrepTransaction
Describes a product being used as a PREP transaction to create a batch.

### Input Parameters
1. **batch_prep INT**: the batch which the product is being used for
2. **product_prep INT**: the product which is contributing to the batch
3. **quantity_prep DECIMAL(10,3)**: the amount of product that is being prepped to created the batch

### Verifies
- **batch_prep** is not NULL and refers to pending batch
- **product_prep** is not NULL and refers to a product
- price and conversion factor associated with **product_prep** are not NULL and strictly positive
- internal_num associated with **product_prep** is not NULL and refers to an item
- recipe associated with **batch_prep** is not NULL and refers to a recipe
- quantity associated with **batch_prep** is not NULL and strictly positive
- batch_status associated with **batch_prep** is not NULL and `PENDING`
- creator of **batch_prep** is not NULL and associated with an employee number 
- internal_num associated with **product_prep** is an ingredient of the recipe associated with **batch_prep**
- **product_prep** is associated with an item that is an ingredient of the recipe associated with **batch_prep**
- **quantity_prep** is not NULL and strictly positive
- sum of **quantity_prep** and prep transactions associated with  **batch_prep** that have a product with the same internal number as **product_prep** does not exceed the amount of that ingredient

### Behavior
- Calculate how much **quantity_prep** of **product_prep** is worth based off the price of the product
- Insert new `PENDING` prep transaction into InventoryTransaction

## activateBatch
Verifies that enough products have been allocated to this batch in `InventoryTransaction` to create the batch.

Activates the batch so that it can be used — represents the actual creation of the batch by setting the creation time and expiration date.

### Input Parameters
1. **active_batch INT**: the batch that is being activated  
2. **batch_approver VARCHAR(20)**: employee number of the manager approving the batch  

### Verifies
- batch number is not `NULL`
- batch exists in `Batch`
- batch approver is not `NULL` or blank
- batch approver exists in `Employee`
- batch approver is a manager
- batch status is `PENDING`
- batch has a valid `recipe_num`
- referenced recipe exists and is active
- batch `prepared_quantity` is greater than `0`
- batch has a valid creator
- batch creator exists in `Employee`
- recipe has a valid positive shelf life
- each ingredient references a valid item
- each ingredient quantity is greater than `0`
- total allocated `PREP` quantities match required ingredient quantities for the batch
- at least one pending `PREP` transaction exists for the batch
- each `PREP` transaction has a valid transaction number
- each `PREP` transaction references a valid product
- each `PREP` transaction has a valid creator
- each `PREP` transaction quantity is greater than `0`
- each referenced product exists in `ProductInventory`
- sufficient inventory exists for each allocated product
- referenced `PrepPlan` exists when provided

### Behavior
- starts a transaction to ensure atomic execution
- locks the batch row using `FOR UPDATE`
- retrieves batch details (recipe, quantity, plan, creator)
- retrieves recipe shelf life
- iterates through recipe ingredients
- calculates total required quantity per ingredient
- validates that allocated `PREP` transactions satisfy requirements
- iterates through pending `PREP` transactions
- locks each corresponding `ProductInventory` row
- deducts allocated quantities from `ProductInventory`
- updates `PREP` transactions to `APPROVED`
- records the approving manager in `approved_by`
- updates batch status to `ACTIVE`
- sets expiration timestamp based on recipe shelf life
- marks associated `PrepPlan` as `COMPLETED` when applicable
- inserts a `CREATE` record into `BatchTransaction`
- commits the transaction on success
- rolls back the transaction on failure


## modifyBatch
Creates WASTE or ADJUST transactions that will affect a given batch

### Input Parameters
1. **batch_modified INT**: the batch which the transaction affects
2. **amount_modified DECIMAL(10,3)**: the amount of the batch which s being changed
3. **modify_type (VARCHAR(20))**: either `WASTE` or `ADJUST`
4. **modify_reason (VARCHAR(64))**: the reason the transaciton is being created
5. **modify_creator (VARCHAR(20))**: the employee who is creating the transaciton

### Verifies
- **batch_modified** is not NULL and referes to an active batch
- **modify_type** is either `WASTE` or `ADJUST`
- **amount_modified** is non-zero and if making a waste transaction, not negative as well
- **modify_reason** is not NULL or an empty string
- **modify_creator** is not NULL and refers to an employee num

### Behavior 
- Inserts a pending Batch Transaction into the BatchTransaction table if the procedure was given valid information

## resolveBatchModify
Used to approve or deny a batch modificiation which is in the form of a BatchTransaction of type `WASTE` or `ADJUST`

### Parameters
1. **trans_num INT**: the transaction number which is being resolved
2. **modify_approver VARCHAR(20)**: the employee resolving the transaction
3. **trans_resolution VARCHAR(20)**: the resolution choice, either `APPROVED` or `DENIED`

### Verifies
- **trans_num** is not NULL and referes to a transaction in BatchTransaction
- **trans_num** has a `PENDING` status
- **trans_num** has a non-NULL reason
- **trans_num** is of type `WASTE` or `ADJUST`
- **trans_num** has a creator that is a valid employee
- **trans_num** has a batch which is either `ACTIVE` or `DEPLETED`
- **trans_num** has a valid datetime which is before the current time
- **modify_approver** is not NULL and a valid manager
- **trans_resolution** is either `APPROVED` or `DENIED`
- the changing of the quantity of the batch does not result in a negative remaining_quantity

### Behavior
- Lock corresponding BatchTransaction to ensure it is not resolved more than once
- Verify all parameter and information in the transaction being resolved
- Lock the corresponding batch so that it may not be altered until the transaction affects it
- Perform the neccesary calculation to the final remaining_quantity and update the batch's remaining quantity and status accordingly
- Set the BatchTransaction to `APPROVED`

## useBatch
Creates a `USE` transactions which is approved and consumes the remaining quantity of that batch. 

### Input Parameters
1. **batch_used INT**: The batch which is being used
2. **quantity_used DECIMAL(10,3)**: The quantity of the recipe being used, measured in the units corresponding to the recipe of the batch
3. **use_creator VARCHAR(20)**: Employee number of who is creating the transaction 

### Verifies
- **batch_used** is not NULL and refers to an active batch
- **quantity_used** is not NULL and strictly positive
- **use_creator** is not NULL and refers to an employee
- the remaining_quantity in the batch is not NULL and strictly positive
- the deduction of **quantity_used** from the remaining quantity doesn't result in negative number 

### Behavior
- starts transaction to lock **batch_used**
- update Batch remaining_quantity to the updated value and the batch_status to DEPLETED if the new remaining_quantity is 0
- inserts an approved  USE transaction into BatchTransaction 


## useRecipe
Given a recipe, creates use transaction for the oldest batches until the full use quantity has been allocated 

### Input Parameters
1.  **use_recipe INT**: Recipe being used
2. **use_quantity DECIMAL(10,3)**: The quantity of the recipe being used
3. **use_creator VARCHAR(20)**: The employee creating the transactions 

### Verifies 
- **use_recipe** is not NULL and refers to a non `PENDING` recipe 
- **use_quantity** is not NULL and strictly positive 
- **use_creator** is not NULL and refers to an employee
- there are enough remaining_quantity among the active batches to account for the **use_quantity**

### Behavior
- start transaction and lock each batch which is being consumed in useRecipe
- start with the oldest batch which has a recipe_num fitting **use_recipe** and take away all its **use_quantity** or decrements **use_quantity** by its remaining quantity if **use_quantity** exceeds on-hand values and depletes the batch and moves on to the next oldest batch
- Inserts approved use transaction into BatchTransaction for each batch that some is used from

# Snapshot Procedures

## createInventorySnapshotRecord
Creates an inventory snapsshot record which will have snapshots which count the products for that record refering to it.

### Input Parameters
1. recorder: employee number of who is creating the snapshot and counting the inventory, must be a manager
### Goals
- Verifies recorder is a valid manager
- Insert into InventorySnapshotRecord with the CURRENT_TIMESTAMP and PENDING status

---

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

---

## createRecipeSnapshot
Aggregates the batches of the same recipe type to compare that with the amount of that recipe that is physically counted

### Input Parameters
1. **snap_id INT**: the snapshot record which this snapshot is referring to 
2. **recipe_snapshot INT** refers to the recipe being counted
3. **recipe_count DECIMAL(10,3)** The amount of the recipe physically counted

### Verifies
- **snap_id** is not NULL and refers to a `PENDING` snapshot record
- **recipe_snapshot** is not NULL and refers to a non `PENDING` recipe
- **recipe_count** is not NULL and non-negative
- the remaining quantity for each active batch with **recipe_snapshot** is not NULL and is positive
- there is not already a snapshot assigned to **snap_id** recording for **recipe_snapshot**
### Behavior
- Sums the remaining quantities of each batch with recipe type **recipe_snapshot** and records this as the expected recipe level
- Inserts into RecipeSnapshot the amount physically counted and the expected recipe level along with the recipe and snapshot record information 
-  


---

## completeSnapshot
Completes an inventory snapshot by updating record and verifying that all products with non-zero ProductInventory quantities and all recipes that have active batches with strictly positive quantities have snapshot entries.

### Input Parameters
1. completed_snapshot: refers to the snapshot record which needs to be resolved
### Verifies
- Verify that snapshot is valid
- Verify that the snapshot's status is PENDING
- Each ProductInventory's entry with nonzero quantity has a corresponding ProductSnapshot entry
- Each recipe that has an ACTIVE batch with a nonzero remaining quantity has a corresponding RecipeSnapshot entry
- Update snapshot_status in InventorySnapshotRecord to COMPLETED

###  Behavior
- locks SnapshotRecord **completed_snapshot** so it can't be updated more than once
- updates inventorySnapshotRecord to be completed
