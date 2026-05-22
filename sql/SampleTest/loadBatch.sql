CALL createPrepPlan(1, CURRENT_DATE, 20, "FULL", "56881");		-- creates prep plan to make 20 cheeseburgers
CALL createPrepPlan(2, CURRENT_DATE, 100, "FULL", "56881");		-- creates prepplan to make 400 oz of loaded fries
CALL createPrepPlan(3, CURRENT_DATE, 20, "FULL", "56881");		-- creates prepplan to make 20 chicken baskets
SELECT * FROM PrepPlan;


-- executes all prepplans
CALL executePrepPlan(1, "56884");								
CALL executePrepPlan(2, "56884");
CALL executePrepPlan(3, "56884");
SHOW ERRORS;




SELECT * FROM Batch;
-- batch 1: Cheeseburger, quantity 20
CALL createPrepTransaction(1, 20, 20.0);
SHOW ERRORS;
CALL createPrepTransaction(1, 17, 0.2);
CALL createPrepTransaction(1, 2, 0.2);
CALL createPrepTransaction(1, 3, 40.0);
CALL createPrepTransaction(1, 4, 5.0);
CALL createPrepTransaction(1, 7, 2.0);
CALL activateBatch(1, '56881');
SHOW ERRORS;

-- batch 2: Loaded Fry, quantity 400
CALL createPrepTransaction(2, 19, 100);
CALL createPrepTransaction(2, 12, 40.0);
CALL createPrepTransaction(2, 17, 4.0);
CALL activateBatch(2, '56881');
SHOW ERRORS;


-- batch 3: Chicken Basket, quantity 20
CALL createPrepTransaction(3, 19, 5.0);
CALL createPrepTransaction(3, 13, 10.0);
CALL createPrepTransaction(3, 15, 0.2);
CALL activateBatch(3, '56881');

SELECT * FROM Batch;
SELECT * FROM BatchTransaction;
SELECT 
	it.quantity,
    it.approval_status,
    it.product_num,
    p.internal_num
 FROM InventoryTransaction as it
 JOIN Product as p
	ON p.product_num = it.product_num
	WHERE transaction_type = 'PREP';
