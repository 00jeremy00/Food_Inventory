CALL createPrepPlan(1, CURRENT_DATE, 20, "FULL", "56881");		-- creates prepplan to make 20 cheeseburgers
CALL createPrepPlan(2, CURRENT_DATE, 100, "FULL", "56881");		-- creates prepplan to make 100 oz of loaded fries
CALL createPrepPlan(3, CURRENT_DATE, 20, "FULL", "56881");		-- creates prepplan to make 20 chicken baskets
SELECT * FROM PrepPlan;

SELECT * FROM Ingredient
	WHERE recipe_num = 2;

-- executes all prepplans
CALL executePrepPlan(1, "56884");								
CALL executePrepPlan(2, "56884");
CALL executePrepPlan(3, "56884");
SHOW ERRORS;

DELETE FROM InventoryTransaction
	WHERE batch_num = 2;


-- batch 1: Cheeseburger, quantity 20
CALL createPrepTransaction(1, 20, 20.0);
CALL createPrepTransaction(1, 17, 0.2);
CALL createPrepTransaction(1, 2, 0.2);
CALL createPrepTransaction(1, 3, 40.0);
CALL createPrepTransaction(1, 4, 5.0);
CALL createPrepTransaction(1, 7, 2.0);
CALL activateBatch(1, '56881');


-- batch 2: Loaded Fry, quantity 100
CALL createPrepTransaction(2, 19, 100.0);
CALL createPrepTransaction(2, 12, 40.0);
CALL createPrepTransaction(2, 17, 4.0);
CALL activateBatch(2, '56881');

-- batch 3: Chicken Basket, quantity 20
CALL createPrepTransaction(3, 19, 5.0);
CALL createPrepTransaction(3, 13, 10.0);
CALL createPrepTransaction(3, 15, 0.2);
CALL activateBatch(3, '56881');

SELECT * FROM Batch;
