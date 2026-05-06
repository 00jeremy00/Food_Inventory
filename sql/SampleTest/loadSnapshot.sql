USE FOOD;

-- ===============================
-- Snapshot Load
-- ===============================
-- Creates one pending snapshot record.
-- Then creates product and recipe snapshots using current expected quantities.
-- Counted quantities intentionally differ in some rows to test variance reports.

CALL createSnapshotRecord('56881');
SHOW ERRORS;

SELECT * FROM SnapshotRecord;
-- If this is the first snapshot in a fresh load, this should be 1.
-- Change this if your snapshot_id is different.
SET @snapshot_id = LAST_INSERT_ID();

SELECT @snapshot_id AS snapshot_id;


-- ===============================
-- Product Snapshots
-- ===============================

CALL createProductSnapshot(@snapshot_id, 1, 20.000);      -- exact match
CALL createProductSnapshot(@snapshot_id, 2, 3.500);       -- shortage: expected 3.800
CALL createProductSnapshot(@snapshot_id, 3, 442.000);     -- overcount: expected 440
CALL createProductSnapshot(@snapshot_id, 4, 94.000);      -- shortage: expected 95
CALL createProductSnapshot(@snapshot_id, 5, 400.000);     -- exact match
CALL createProductSnapshot(@snapshot_id, 6, 47.000);      -- shortage: expected 48
CALL createProductSnapshot(@snapshot_id, 7, 48.000);      -- exact match
CALL createProductSnapshot(@snapshot_id, 9, 60.000);      -- exact match
CALL createProductSnapshot(@snapshot_id, 10, 1000.000);   -- exact match
CALL createProductSnapshot(@snapshot_id, 11, 36.000);     -- exact match
CALL createProductSnapshot(@snapshot_id, 12, 184.000);    -- shortage: expected 185
CALL createProductSnapshot(@snapshot_id, 13, 91.000);     -- overcount: expected 90
CALL createProductSnapshot(@snapshot_id, 14, 54.000);     -- exact match
CALL createProductSnapshot(@snapshot_id, 15, 3.700);      -- shortage: expected 3.800
CALL createProductSnapshot(@snapshot_id, 16, 4.000);      -- exact match
CALL createProductSnapshot(@snapshot_id, 17, 1.250);      -- overcount: expected 1.140
CALL createProductSnapshot(@snapshot_id, 18, 15000.000);  -- exact match
CALL createProductSnapshot(@snapshot_id, 19, 493.500);    -- shortage: expected 495
CALL createProductSnapshot(@snapshot_id, 20, 100.000);    -- exact match

select * FROM RecipeSnapshot;
-- ===============================
-- Recipe Snapshots
-- ===============================
-- Expected values should be calculated by createRecipeSnapshot
-- from active batch remaining quantities:
-- Recipe 1 expected: 14
-- Recipe 2 expected: 364
-- Recipe 3 expected: 21

CALL createRecipeSnapshot(@snapshot_id, 1, 13.000);   -- shortage: expected 14
CALL createRecipeSnapshot(@snapshot_id, 2, 364.000);  -- exact match
CALL createRecipeSnapshot(@snapshot_id, 3, 22.000);   -- overcount: expected 21


-- ===============================
-- Complete Snapshot
-- ===============================

CALL completeSnapshot(@snapshot_id);



-- ===============================
-- Validation Queries
-- ===============================

SELECT *
FROM SnapshotRecord
WHERE snapshot_id = @snapshot_id;

SELECT *
FROM ProductSnapshot
WHERE snapshot_id = @snapshot_id
ORDER BY product_num;

SELECT *
FROM RecipeSnapshot
WHERE snapshot_id = @snapshot_id
ORDER BY recipe_num;

SELECT *
FROM ProductSnapshotSummary
WHERE snapshot_id = @snapshot_id
ORDER BY product_num;

SELECT *
FROM RecipeSnapshotSummary
WHERE snapshot_id = @snapshot_id
ORDER BY recipe_num;

SHOW ERRORS;