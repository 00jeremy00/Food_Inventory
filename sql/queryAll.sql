# Select Waste within the month of March of 2026
SELECT * FROM WasteAdjustInfo
WHERE transaction_type = 'WASTE'
AND transaction_date >= "2026-03-01 00:00:00"
AND transaction_date < "2026-04-01 00:00:00";

# Select Adjustments and Waste done by Jeremy
SELECT * FROM WasteAdjustInfo
WHERE manager_name = 'Jeremy Dickinson';

# get the total waste of each item
SELECT 
internal_num,
internal_name,
SUM(quantity) as total_waste
FROM WasteAdjustInfo
WHERE transaction_type = 'WASTE'
GROUP BY internal_num, internal_name;
SELECT * FROM InventoryTransaction;

# select all invoiceline entries

SELECT 
i.invoice_num,
i.vendor_pnum as product_number,
p.vendor_pname as product_name,
i.quantity
FROM InvoiceLine AS i JOIN Product AS p
ON i.vendor_pnum = p.vendor_pnum;


# get inventory data

SELECT 
inv.internal_num, 
it.internal_name,
inv.quantity,
it.internal_unit as unit
FROM Inventory as inv LEFT JOIN Item as it
ON inv.internal_num = it.internal_num;

# get the total use of each item
SELECT 
internal_num,
internal_name,
SUM(quantity) as total_use
FROM WasteAdjustInfo
WHERE transaction_type = 'USE'
GROUP BY internal_num, internal_name;

# gets recent adjustments made to inventory
SELECT *
FROM WasteAdjustInfo
WHERE transaction_type = 'ADJUST'
ORDER BY transaction_date DESC;

SELECT * FROM InventoryTransaction;