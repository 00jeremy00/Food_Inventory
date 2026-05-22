-- ===============================
-- Manual inventory transaction tests
-- ===============================
-- These transactions are used to test:
-- 1. pending transaction creation
-- 2. manager approval workflow
-- 3. waste / adjust / use behavior
-- 4. inventory updates after approval


-- ---------------------------------
-- Fries (product 19)
-- ---------------------------------

CALL createUseTransaction(19, 40, '56881'); -- create pending USE transaction for 40 lb of fries
CALL createAdjustTransaction(19, 40, '56881', 'improper setup'); -- create pending ADJUST transaction to set fries inventory to 40 lb

CALL resolveInventoryTransaction(21, 'APPROVED', '56881'); -- approve ADJUST transaction
CALL resolveInventoryTransaction(20, 'APPROVED', '56881'); -- approve USE transaction

CALL createWasteTransaction(19, 0.5, '56881', 'dropped on the floor'); -- create pending WASTE transaction for 0.5 lb of fries
CALL resolveInventoryTransaction(22, 'APPROVED', '56881'); -- attemps to approve transaction but blocks to avoid negative inventory 

CALL createAdjustTransaction(19, -4.6, '56881', 'inventory correction'); -- create pending ADJUST transaction to reduce fries inventory by 4.6 lb
CALL resolveInventoryTransaction(23, 'APPROVED', '56881'); -- attemps to approve transaction but blocks to avoid negative inventory 


-- ---------------------------------
-- Bacon (product 12)
-- ---------------------------------

CALL createUseTransaction(12, 3.0, '56881'); -- create pending USE transaction for 3 lb of bacon
CALL resolveInventoryTransaction(24, 'APPROVED', '56881'); -- approve bacon use
SHOW ERRORS;
CALL createWasteTransaction(12, 1.0, '56881', 'overcooked during prep'); -- create pending WASTE transaction for 1 lb of bacon
CALL resolveInventoryTransaction(25, 'APPROVED', '56881'); -- approve bacon waste
SHOW ERRORS;

SELECT * FROM ProductInventory;

-- ---------------------------------
-- Tomatoes (product 7)
-- ---------------------------------

CALL createUseTransaction(7, 4.5, '56881'); -- create pending USE transaction for 4.5 lb of tomatoes
CALL resolveInventoryTransaction(26, 'APPROVED', '56881'); -- approve tomato use

CALL createWasteTransaction(7, 1.2, '56881', 'spoiled produce'); -- create pending WASTE transaction for spoiled tomatoes
CALL resolveInventoryTransaction(27, 'APPROVED', '56881'); -- approve tomato waste


-- ---------------------------------
-- Buns (product 3)
-- ---------------------------------

CALL createUseTransaction(3, 24, '56881'); -- create pending USE transaction for 24 burger buns
CALL resolveInventoryTransaction(28, 'APPROVED', '56881'); -- approve bun use

CALL createAdjustTransaction(3, -6, '56881', 'damaged packaging count correction'); -- create pending ADJUST transaction to reduce bun count by 6
CALL resolveInventoryTransaction(29, 'APPROVED', '56881'); -- approve bun adjustment


-- ---------------------------------
-- Chicken breast (product 5)
-- ---------------------------------

CALL createUseTransaction(5, 12.0, '56881'); -- create pending USE transaction for 12 lb chicken breast
CALL resolveInventoryTransaction(30, 'APPROVED', '56881'); -- approve chicken use

CALL createWasteTransaction(5, 2.0, '56881', 'temperature abuse'); -- create pending WASTE transaction for spoiled chicken
CALL resolveInventoryTransaction(31, 'APPROVED', '56881'); -- approve chicken waste


-- ---------------------------------
-- Ketchup (product 17)
-- ---------------------------------

CALL createUseTransaction(17, 0.75, '56881'); -- create pending USE transaction for 0.75 gal ketchup
CALL resolveInventoryTransaction(32, 'APPROVED', '56881'); -- approve ketchup use

CALL createAdjustTransaction(17, 0.25, '56881', 'partial container found during count'); -- create pending ADJUST transaction increasing ketchup by 0.25 gal
CALL resolveInventoryTransaction(33, 'APPROVED', '56881'); -- approve ketchup adjustment
SHOW ERRORS;

-- ---------------------------------
-- Optional test queries
-- ---------------------------------
SELECT * FROM InventoryTransaction;
SELECT *
FROM InventoryTransaction
WHERE transaction_type <> 'RECEIVE'
ORDER BY transaction_num;

SELECT *
FROM ProductInventory
ORDER BY product_num;