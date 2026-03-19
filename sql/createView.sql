CREATE OR REPLACE VIEW ReceiveInfo AS
SELECT 
	t.transaction_num,
    t.internal_num,
    t.quantity,
    t.transaction_date,
    t.approved_by,
    m.manager_name,
    t.approval_status,
    t.invoice_num,
    t.vendor_pnum,
    t.price_per_unit
FROM Item as i JOIN InventoryTransaction as t
ON i.internal_num = t.internal_num
JOIN Manager as m
ON m.manager_num = t.approved_by
WHERE t.transaction_type = 'RECEIVE';


CREATE OR REPLACE VIEW  WasteAdjustInfo AS
SELECT
t.transaction_num,
t.transaction_date,
t.transaction_type,
i.internal_num,
i.internal_name,
t.quantity,
i.internal_unit,
t.reason,
m.manager_name,
m.manager_num

FROM Item as i JOIN InventoryTransaction as t
ON i.internal_num = t.internal_num
JOIN Manager as m
ON m.manager_num = t.manager_num
WHERE t.transaction_type IN ('ADJUST', 'WASTE');

