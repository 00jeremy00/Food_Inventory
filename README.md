# Restaurant Inventory & Demand Prediction System

## Overview

This project implements a relational database system designed to manage restaurant inventory and supplier purchasing data. The system tracks internal inventory items, vendor-specific product listings, purchase invoices, and inventory transactions.

The database is designed to support both operational inventory management and data-driven analysis. By maintaining clean and structured data, the system enables future machine learning models to predict ingredient demand and optimize purchasing decisions.

Food service inventory systems are often fragmented or poorly integrated. This project demonstrates how a well-designed relational database can provide reliable operational data while also supporting predictive analytics.

---

## Key Features

- Relational inventory database
- Vendor product mapping to internal inventory items
- Invoice and purchasing tracking
- Inventory transaction history (audit trail)
- Automated inventory updates using triggers
- Structured dataset for machine learning demand forecasting

---

## Tech Stack

- **MySQL**
- **SQL** (Triggers, Views, Stored Procedures)
- **Python** (planned for ML modeling)
- **FastAPI** (planned API layer)
- **Git / GitHub**

---


## Setup

1. Create the database:

```sql
CREATE DATABASE FOOD;
USE FOOD;
 ```
---

## ER Diagram

![ER Diagram](./ER_diagram.png)