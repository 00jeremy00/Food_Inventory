
CREATE OR REPLACE VIEW ItemInventoryData AS
SELECT
    i.internal_num,
    i.internal_name,
    i.category,
    i.internal_unit,
    SUM(pi.quantity) AS total_quantity,
    SUM(pi.quantity * (p.price / p.conversion_factor)) AS total_value
FROM ProductInventory pi
JOIN Product p
    ON pi.product_num = p.product_num
JOIN Item i
    ON p.internal_num = i.internal_num
GROUP BY
    i.internal_num,
    i.internal_name,
    i.category,
    i.internal_unit;

DROP VIEW IF EXISTS ReceiveInfo;
CREATE OR REPLACE VIEW ProductInventoryView AS
SELECT
    p.product_num,
    p.vendor_pnum,
    p.vendor_pname,
    v.vendor_num,
    v.vendor_name,
    i.internal_num,
    i.internal_name,
    i.category,
    i.internal_unit,
    p.purchase_unit,
    pi.quantity,
    p.price,
    p.conversion_factor,
    (p.price / p.conversion_factor) AS price_per_internal_unit,
    (pi.quantity * (p.price / p.conversion_factor)) AS total_value
FROM ProductInventory pi
JOIN Product p
    ON pi.product_num = p.product_num
JOIN Item i
    ON p.internal_num = i.internal_num
JOIN Vendor v
    ON p.vendor_num = v.vendor_num;


CREATE OR REPLACE VIEW ProductVarianceView AS
SELECT
	s.snapshot_id,
	p.product_num,
    p.vendor_pname,
    i.internal_num,
    i.internal_name,
	s.expected_quantity,
    s.counted_quantity,
    (s.counted_quantity - s.expected_quantity) AS product_variance,
    (p.price / p.conversion_factor) AS price_per_unit,
    ((s.counted_quantity - s.expected_quantity) *(p.price / p.conversion_factor)) AS price_variance
FROM
	InventorySnapshot AS s LEFT JOIN Product AS p
    ON s.product_num = p.product_num
    LEFT JOIN Item AS  i
    ON p.internal_num = i.internal_num;
SHOW ERRORS;