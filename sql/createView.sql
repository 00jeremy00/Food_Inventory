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

SELECT * FROM ItemInventoryData;
CREATE OR REPLACE VIEW ActiveBatchSummary AS
SELECT
	b.batch_num,
    b.recipe_num,
    r.recipe_name,
    b.created_by,
    b.approved_by,
    b.prepared_quantity,
    b.remaining_quantity,
    r.recipe_unit,
    b.expires_at
FROM Batch as b LEFT JOIN Recipe as r
	ON b.recipe_num = r.recipe_num
WHERE b.batch_status = 'ACTIVE';

CREATE OR REPLACE VIEW ProductSnapshotSummary AS
SELECT
	p.product_num,
    p.vendor_pnum,
    p.vendor_pname,
    p.internal_num,
    i.internal_name,
    i.internal_unit,
    s.snapshot_id,
	s.expected_quantity,
    s.counted_quantity,
    (s.counted_quantity - s.expected_quantity) AS variance_quantity,
    CASE
        WHEN s.expected_quantity = 0 THEN NULL
        ELSE ((s.counted_quantity - s.expected_quantity) / s.expected_quantity) * 100
    END AS variance_percent
FROM Product AS p
JOIN ProductSnapshot AS s
	ON p.product_num = s.product_num
JOIN Item AS i
	ON p.internal_num = i.internal_num;


CREATE OR REPLACE VIEW RecipeSnapshotSummary AS
SELECT
	r.recipe_num,
    r.recipe_name,
    r.recipe_status,
    s.snapshot_id,
    s.expected_quantity,
    s.counted_quantity,
    r.recipe_unit,
    (s.counted_quantity - s.expected_quantity) AS variance_quantity,
    CASE
		WHEN s.expected_quantity = 0 THEN NULL
        ELSE ((s.counted_quantity - s.expected_quantity) / s.expected_quantity) * 100
    END AS variance_percent
FROM Recipe AS r 
JOIN RecipeSnapshot AS s
	ON r.recipe_num = s.recipe_num;

CREATE OR REPLACE VIEW RemainingRecipes AS
SELECT
	r.recipe_num,
    r.recipe_name,
    COALESCE(SUM(b.remaining_quantity), 0) AS quantity,
    r.recipe_unit
FROM Recipe AS r
LEFT JOIN Batch AS b
	ON b.recipe_num = r.recipe_num
    AND b.batch_status = 'ACTIVE'
GROUP BY 
	r.recipe_num,
    r.recipe_name,
    r.recipe_unit;
    
CREATE OR REPLACE VIEW ExpiringBatches AS
SELECT
	b.batch_num,
    r.recipe_num,
    r.recipe_name,
    b.plan_num,
    b.remaining_quantity,
    b.expires_at
FROM Batch AS b
JOIN Recipe AS r
	ON b.recipe_num = r.recipe_num
WHERE
	b.batch_status = 'ACTIVE'
	AND b.expires_at <= DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 24 HOUR);