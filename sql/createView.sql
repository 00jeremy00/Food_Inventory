CREATE OR REPLACE VIEW ReceiveInfo AS
SELECT 
t.transaction_num as 'transaction number',
t.transaction_type as "transaction type",
i.internal_num as "item number",
i.internal_name as 'item',
t.quantity as 'quantity',
i.internal_unit as 'unit',
t.invoice_num as 'invoice number',
m.manager_name as 'manager'
FROM Item as i JOIN InventoryTransaction as t
ON i.internal_num = t.internal_num
JOIN Managers as m
ON m.manager_num = t.manager
WHERE t.transaction_type = 'RECEIVE';


CREATE OR REPLACE VIEW  WasteAdjustInfo AS
SELECT
t.transaction_num as 'transaction number',
t.transaction_type as "transaction type",
i.internal_num as "item number",
i.internal_name as 'item',
t.quantity as 'quantity',
i.internal_unit as 'unit',
t.reason as 'reason',
m.manager_name as 'manager'

FROM Item as i JOIN InventoryTransaction as t
ON i.internal_num = t.internal_num
JOIN Managers as m
ON m.manager_num = t.manager
WHERE t.transaction_type IN ('ADJUST', 'WASTE');

