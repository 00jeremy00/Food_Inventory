# Restaurant Inventory & Demand Prediction System

## Overview

This project implements a relational database system designed to manage restaurant inventory and supplier purchasing data. The system tracks internal inventory items, vendor-specific product listings, purchase invoices, and inventory adjustments.

The database is designed to support operational inventory management while also enabling data analysis and machine learning models to predict ingredient demand and optimize purchasing decisions.

Food service inventory systems are often fragmented or poorly integrated. This project aims to demonstrate how a well-designed relational database can provide clean operational data that supports both day-to-day inventory tracking and predictive analytics.

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

---

**Product**

Vendor-specific product listings that map to internal items.

Attributes:

* vendor_pnum (PK)
* internal_num (FK)
* vendor_name
* vendor_num (FK)
* price
* purchase_unit
* conversion_unit

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
* reason

Transaction types may include:

* RECEIVE
* USE
* WASTE
* ADJUST

Positive quantities increase stock while negative quantities decrease stock.

## Inventory Flow

Inventory typically enters the system through supplier invoices.

Example process:

1. A supplier invoice is recorded in the **Invoice** table
2. Purchased products are recorded in **InvoiceLine**
3. A corresponding **Inventory_Transaction** is created to increase stock
4. Inventory consumption, waste, or corrections create
