# Restaurant Inventory & Demand Prediction System

## Overview

This project implements a relational database system designed to manage restaurant inventory and supplier purchasing data. The system tracks internal inventory items, vendor-specific product listings, purchase invoices, and inventory adjustments.

The database is designed to support operational inventory management while also enabling data analysis and machine learning models to predict ingredient demand and optimize purchasing decisions.

Food service inventory systems are often fragmented or poorly integrated. This project aims to demonstrate how a well-designed relational database can provide clean operational data that supports both day-to-day inventory tracking and predictive analytics.

# Key Features
• Relational inventory database
• Vendor product mapping
• Invoice and purchasing tracking
• Inventory transaction history
• Automated inventory updates using triggers
• Clean dataset for machine learning demand forecasting

# Tech Stack
• MySQL
• SQL (Triggers, Views, Stored Procedures)
• Python (future ML modeling)
• FastAPI (optional API layer)
• Git / GitHub

Setup
1. Create database
2. Run scripts in order
createAll.sql
createView.sql
storedProcedures.sql
trigger.sql
loadSampleData.sql

## Goals

The primary goals of this project are:

* Track restaurant inventory using a structured relational database
* Store vendor-specific product listings and pricing
* Record purchase invoices and delivered quantities
* Maintain current stock levels for internal inventory items
* Track all inventory movements through transaction history
* Enable machine learning models to analyze historical usage and forecast demand

## System Design

The system separates **internal inventory items** from **vendor product listings**. This allows multiple supplier products to map to a single internally tracked item.

For example, multiple suppliers may sell chicken breast using different product codes, but they all map to the same internal inventory item.

### Core Entities

**Category**
Represents the classification of an internal inventory item. Categories group similar items together and allow the system to enforce consistent labeling across the inventory database.

Attributes
 * category_name (PK) for example frozen, refrigerated, paper_product, dry_food

**Item**

Internal inventory items used by the restaurant.

Attributes:

* internal_num (PK)
* internal_name
* category
* internal_unit

Example:
Chicken Breast, Roma Tomato, Mozzarella Cheese

**Product**

Vendor-specific product listings that map to internal items.

Attributes:

* vendor_pnum (PK)
* internal_num (FK)
* vendor_name
* vendor_num (FK)
* price
* purchase_unit     - unit in which it is purchased
* conversion_unit   - coversion factor to translate to internal units

This table allows multiple suppliers to provide the same ingredient.

---

**Vendor**

Stores information about food suppliers.

Attributes:

* vendor_num (PK)
* name
* phone_number
* email
* website

Examples include distributors such as Gordon Food Service or produce vendors.

---

**Invoice**

Represents purchase orders or supplier invoices.

Attributes:

* invoice_num (PK)
* date
* vendor_num (FK)

---

**InvoiceLine**

Records individual products purchased on each invoice.

Attributes:

* (invoice_num, vendor_pnum) (PK)
* quantity

---

**Inventory**

Stores the current stock level for each internal inventory item.

Attributes:

* internal_num (PK, FK)
* quantity

Quantities are stored using the internal unit defined in the Item table.

---

**Managers**

Records managers responsible for inventory adjustments.

Attributes:

* manager_id (PK)
* manager_name

---

**Inventory_Transaction**

Tracks all inventory movement events.

Attributes:

* transaction_num (PK)
* internal_num (FK)
* quantity
* date
* type
* manager_id (FK)
* invoice_num (FK)
* reason                - NULL unless WASTE or ADJUST

Transaction types may include:

* RECEIVE               - New product coming in
* USE                   - product getting used such as 100 napkins
* WASTE                 - wasted product
* ADJUST                - ajusting the inventory level 
*ADJUST is the only field where sign matters, others are forced to correspond to adding or removing product.

Positive quantities increase stock while negative quantities decrease stock.

## Inventory Flow

Inventory typically enters the system through supplier invoices.

Example process:

1. A supplier invoice is recorded in the **Invoice** table
2. Purchased products are recorded in **InvoiceLine**
3. A corresponding **Inventory_Transaction** is created to increase stock
4. Inventory consumption, waste, or corrections create

## Inventory Transaction Workflow

The database uses triggers to automatically validate transactions and maintain the current inventory state.

### Workflow

1. An `INSERT` is executed on the `InventoryTransaction` table.
2. Before the row is inserted, the `prevent_negative_inventory` trigger validates the transaction.
3. If the transaction violates business rules (e.g., negative inventory or missing reason), the trigger raises an error and the transaction is rejected.
4. If the transaction is valid, the row is inserted into `InventoryTransaction`.
5. After insertion, the `update_inventory` trigger updates the `Inventory` table by either adjusting the quantity or creating a new inventory record if one does not yet exist.


# Example Queries
Examples from queryAll.sql demonstrating analytics queries.

# Future Work
• Machine learning demand forecasting
• automated reorder predictions
• REST API integration
• dashboard for managers

Author
Jeremy Dickinson  
B.S. Computer Science — University of Maryland Baltimore County