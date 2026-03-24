# Stored Procedures for Restaurant Inventory System

These proceudres are the primary way that the database should be interacted with. They all enforce buiness rules and enure data integrity.

# Procedures

## addInvoiceLine
Adds record in InvoiceLine table which describes products that are received from an vendor associated by an invoice.

### Goals
1. Ensure invoice_num is valid
2. Ensure that the associated invoice has not already been APPROVED or DENIED
3. Validate manager approval credentials
4. Validate that product_num is associated with a valid product
5. Verify that quantity incoming is strictly positive
6. Verify that the vendor associated with the invoice sells the product
7. Select necceary information from product to convert new_quantity to internal units
8. Convert total price to price per internal unit
9. Perform insertion into InvoiceLine with price and quantity in terms of initial input
10. Insert into InventoryTransaction with price and quantity in terms of internal units