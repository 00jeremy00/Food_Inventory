DROP PROCEDURE IF EXISTS addRecipe;
DROP PROCEDURE IF EXISTS addIngredient;
DROP PROCEDURE IF EXISTS createPrepPlan;
DROP PROCEDURE IF EXISTS createUnplannedBatch;
DROP PROCEDURE IF EXISTS executePrepPlan;
DROP PROCEDURE IF EXISTS activateBatch;
DROP PROCEDURE IF EXISTS createPrepTransaction;

DELIMITER $$

CREATE PROCEDURE addRecipe(
	IN new_recipe_name VARCHAR(64),
    IN new_active BOOLEAN,
    in shelf_life_hour DECIMAL(10,3)
)
BEGIN
	-- validates recipe name
	IF new_recipe_name IS NULL OR TRIM(new_recipe_name) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Recipe must have name';
        
	-- ensures active status is not NULL
	ELSEIF new_active IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid active status';
	ELSEIF shelf_life_hour IS NULL OR shelf_life_hour <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'shelf life must be strictly positive';
	END IF;
    
    
    INSERT INTO Recipe(
		recipe_name,
        is_active,
        shelflife
	) VALUES(
       TRIM(new_recipe_name),
       new_active,
       shelf_life_hour
	);
    
END $$

CREATE PROCEDURE addIngredient(
	IN new_item VARCHAR(20),
    IN ingredient_recipe INT,
    IN new_quantity DECIMAL(10,3)
)
BEGIN
	DECLARE v_count INT;
    
    -- verifies recipe number is valid
    IF ingredient_recipe IS NULL OR ingredient_recipe < 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Recipe Number';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Recipe
    WHERE recipe_num = ingredient_recipe;
    
    -- verifies recipe number referes to a real recipe
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Recipe not found';
    
    -- verifies that item has a valid string
    ELSEIF new_item IS NULL or TRIM(new_item) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'item number invalid';
	END IF;
    
    SELECT COUNT(*) 
    INTO v_count
    FROM Item
    WHERE internal_num = new_item;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Item does not exist';
	ELSEIF new_quantity <= 0 OR new_quantity is NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ingredient quantity is invalid';
	END IF;
    
    INSERT INTO Ingredient(
		recipe_num,
		internal_num,
        quantity
    ) VALUES(
		ingredient_recipe,
		new_item,
        new_quantity
    );
    
END$$

CREATE PROCEDURE createPrepPlan(
	IN new_plan_recipe INT,
    IN new_plan_date DATE,
    IN new_quantity DECIMAL(10,3),
    IN new_plan_shift VARCHAR(20),
    IN new_planner VARCHAR(20)
)
BEGIN
	DECLARE v_count INT;
    DECLARE recipe_active BOOLEAN;
    
    -- Verify that recipe is valid
    IF new_plan_recipe IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E01]: recipe is NULL';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Recipe
    WHERE recipe_num = new_plan_recipe;
    
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E02]: recipe does not exist';
	END IF;
    
    SELECT is_active 
    INTO recipe_active
    FROM Recipe
    WHERE recipe_num = new_plan_recipe;
    
    IF NOT recipe_active THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E03]: recipe is inactive';
	END IF;
    
    IF new_plan_date IS NULL OR new_plan_date < CURRENT_DATE THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E04]: plan date is invalid';
    ELSEIF new_quantity IS NULL OR new_quantity <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E05]: planned recipe quantity is invalid';
	END IF;
    
    IF new_plan_shift IS NULL OR TRIM(new_plan_shift) = '' THEN
		SET new_plan_shift = NULL;
	ELSE 
		SELECT COUNT(*)
        INTO v_count
        FROM Shift
        WHERE shift_name = new_plan_shift;
        
        IF v_count = 0 THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'createPrepPlan [E06]: Non Null shift does not exist';
		END IF;
	END IF;
    
    IF new_planner IS NULL OR TRIM(new_planner) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E07]: Invalid employee who made plan';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = new_planner;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E08]: Employee does not exist';
	END IF;
    
    INSERT INTO PrepPlan(
		recipe_num,
		plan_date,
		planned_quantity,
		planned_shift,
		planned_by,
        plan_status
    ) VALUES(
		new_plan_recipe,
        new_plan_date,
        new_quantity,
        new_plan_shift,
        new_planner,
        'PENDING'
    );
END$$

CREATE PROCEDURE createUnplannedBatch(
	IN batch_recipe INT,
    IN recipe_quantity DECIMAL(10,3),
    IN batch_creator VARCHAR(20)
)
BEGIN
	DECLARE v_count INT;
    
    IF batch_recipe IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'createBatch [E01]: Recipe is NULL';
	END IF;

	SELECT COUNT(*)
	INTO v_count
	FROM Recipe
	WHERE recipe_num = batch_recipe;
        
	IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'createBatch [E02]: Recipe does not exist';
	
    ELSEIF recipe_quantity IS NULL or recipe_quantity <= 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'createBatch [E03]: Invalid recipe quantity';
        
	ELSEIF batch_creator IS NULL OR TRIM(batch_creator) = '' THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'createBatch [E04]: Batch creator is NULL';
	END IF;
    
	SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = batch_creator;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'createBatch [E05]: Employee not found';
	END IF;
    
    INSERT INTO Batch(
		recipe_num,
        created_on, 
        created_by,
        quantity_prepared,
        quantity_remaining,
        expires_at,
        plan_num,
        batch_status
    ) VALUES(
		batch_recipe,
        NULL,
        batch_creator,
        recipe_quantity,
        recipe_quantity,
        NULL,
        NULL,
        'PENDING'
    );
        
END$$

CREATE PROCEDURE executePrepPlan(
	IN plan_execute INT,
    IN batch_creator VARCHAR(20)
)
BEGIN 
	DECLARE v_count INT;
    DECLARE verify_recipe INT;
    DECLARE verify_quantity DECIMAL(10,3);
    DECLARE verify_date DATE;
    DECLARE verify_shift VARCHAR(20);
    DECLARE verify_status VARCHAR(20);
    DECLARE verify_start TIME;
    DECLARE verify_end TIME;
    
    IF plan_execute IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E01]: plan_num is NULL';
	END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM PrepPlan
    WHERE plan_num = plan_execute;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E02]: Plan does not exist';
	END IF;
    
    IF batch_creator IS NULL OR TRIM(batch_creator) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E03]: batch_creator is NULL';
	END IF;
    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = batch_creator;
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E04]: Employee not found';
	END IF;

    SELECT recipe_num, plan_date, planned_quantity, planned_shift, plan_status
    INTO verify_recipe, verify_date, verify_quantity, verify_shift, verify_status
    FROM PrepPlan
    WHERE plan_num = plan_execute;
    
    IF verify_recipe IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E05]: recipe_num is NULL';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Recipe
    WHERE recipe_num = verify_recipe
    AND is_active = TRUE;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E06]: Recipe not found';
	ELSEIF verify_date IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E07]: plan_date is NULL';
	ELSEIF verify_date <> CURRENT_DATE THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E08]: Batch date must match plan date';
	ELSEIF verify_quantity IS NULL OR verify_quantity <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E09]: Invalid quantity';
	ELSEIF verify_shift IS NOT NULL OR TRIM(verify_shift) <> '' THEN
		SELECT COUNT(*)
		INTO v_count
		FROM Shift
		WHERE shift_name = verify_shift;
    
		IF v_count = 0 THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'executePrepPlan [E11]: Shift not found';
		END IF;
		
		SELECT start_time, end_time
		INTO verify_start, verify_end
		FROM Shift
		WHERE shift_name = verify_shift;
    
		IF CURRENT_TIME > verify_end OR CURRENT_TIME < verify_start THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'executePrepPlan [E12]: Outiside scheduled shift time.';
		END IF;
    END IF;
    
    IF verify_status <> 'PENDING' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E13]: Plan must be PENDING to execute';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Batch
    WHERE plan_num = plan_execute;
    
    IF v_count <> 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E14]: Batch for plan already exists';
	END IF;
    
    INSERT INTO Batch(
		recipe_num,
        created_on, 
        created_by,
        prepared_quantity,
        remaining_quantity,
        expires_at,
        plan_num,
        batch_status
    ) VALUES(
		verify_recipe,
        NULL,
        batch_creator,
        verify_quantity,
        verify_quantity,
        NULL,
        plan_execute,
        'PENDING');
END$$

CREATE PROCEDURE createPrepTransaction(
	IN batch_prep INT,
    IN product_prep INT,
    IN quantity_prep DECIMAL(10,3)
)
BEGIN
	DECLARE v_count INT;
    DECLARE product_item VARCHAR(20);
    DECLARE batch_recipe INT;
    DECLARE ingredient_quantity DECIMAL(10,3);
    DECLARE recipe_quantity DECIMAL(10,3);
    DECLARE running_item_total DECIMAL(10,3);
    DECLARE verify_status VARCHAR(20);
    DECLARE batch_creator VARCHAR(20);
    DECLARE product_price DECIMAL(10,3);
    DECLARE product_factor DECIMAL(10,3);
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    IF batch_prep IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E01] batch num is NULL';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Batch
    WHERE batch_num = batch_prep;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E02] batch not found';
	ELSEIF product_prep IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E03] product num is NULL';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Product
    WHERE product_num = product_prep;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E04] product not found';
	ELSEIF quantity_prep IS NULL OR quantity_prep <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E05] quantity to prep is invalid';
	END IF;
    
	SELECT internal_num, price, conversion_factor
    INTO product_item, product_price, product_factor
    FROM Product 
    WHERE product_num = product_prep;
    
    IF product_item is NULL OR TRIM(product_item) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E06] item associated with product is NULL';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Item
    WHERE internal_num = product_item;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E07] Item associated with product not found';
	ELSEIF product_price IS NULL OR product_price <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E08] Product price is invalid';
	ELSEIF product_factor IS NULL OR product_factor <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E09] product conversion factor is invali';
    END IF;
    
    SET product_price = product_price / product_factor;
    
    START TRANSACTION;
    
    SELECT recipe_num, prepared_quantity, batch_status, created_by
    INTO batch_recipe, recipe_quantity, verify_status, batch_creator
    FROM Batch
    WHERE batch_num = batch_prep
    FOR UPDATE;
    
    IF recipe_quantity IS NULL OR recipe_quantity <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E10] quantity of recipe to prepare is invalid ';    
    ELSEIF batch_recipe IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E11] recipe associated with batch is NULL';
	ELSEIF verify_status <> 'PENDING' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E12] status of batch must be PENDING';
	ELSEIF batch_creator IS NULL OR TRIM(batch_creator) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E13] batch creator is NULL';		
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = batch_creator;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E14] employee not found';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Recipe
    WHERE recipe_num = batch_recipe
		AND is_active = TRUE;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E15] active recipe not found';
	END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Ingredient
    WHERE recipe_num = batch_recipe
		AND internal_num = product_item;
        
	IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E16] Product is not an ingredeint of recipe';
    END IF;
        
    SELECT quantity
    INTO ingredient_quantity
    FROM Ingredient
    WHERE recipe_num = batch_recipe
		AND internal_num = product_item;
	
    IF ingredient_quantity IS NULL OR ingredient_quantity <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E17] invalid quantity of ingredient required for recipe';
    END IF;
    
    SET ingredient_quantity = ingredient_quantity * recipe_quantity;
    
    
    SELECT COALESCE(SUM(it.quantity), 0)
    INTO running_item_total
    FROM InventoryTransaction as it INNER JOIN Product as p
		ON it.product_num = p.product_num
    WHERE it.batch_num = batch_prep
		AND p.internal_num = product_item
        AND it.transaction_type = 'PREP';
	
    IF quantity_prep + running_item_total > ingredient_quantity THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepTransactions [E18] invalid quantity of ingredient required for recipe';
    END IF;

    INSERT INTO InventoryTransaction(
		transaction_type,
		quantity,
		transaction_date,
		approved_by,
		created_by,
		approval_status,
		invoice_id,
		product_num,
		price_per_unit,
		batch_num,
		reason
    ) VALUES(
        'PREP',
		quantity_prep,
        CURRENT_TIMESTAMP,
        NULL,
        batch_creator,
        'PENDING',
        NULL,
        product_prep,
        product_price,
        batch_prep,
        NULL
    );
	COMMIT;
END$$

CREATE PROCEDURE activateBatch(
	IN active_batch INT,
    IN batch_approver VARCHAR(20)
)
BEGIN
	DECLARE v_count INT;
    DECLARE verify_status VARCHAR(20);
    DECLARE batch_recipe INT;
    DECLARE batch_plan INT;
    DECLARE recipe_quantity DECIMAL(10,3);
	DECLARE done INT DEFAULT FALSE;
    DECLARE ingredient_item VARCHAR(20);
    DECLARE needed_quantity DECIMAL(10,3);
    DECLARE prep_quantity DECIMAL(10,3);
    DECLARE prep_product INT;
    DECLARE recipe_life DECIMAL(10,3);
    DECLARE prep_transaction INT;
    DECLARE transaction_creator VARCHAR(20);
	DECLARE alloc_product INT;
	DECLARE alloc_quantity DECIMAL(10,3);
	DECLARE current_inventory DECIMAL(10,3);

    DECLARE cur CURSOR FOR				-- gets transaction info for transactions of selected invoice
        SELECT internal_num, quantity
        FROM Ingredient
        WHERE recipe_num = batch_recipe;

	DECLARE cur_prep CURSOR FOR
		SELECT transaction_num, product_num, quantity, created_by
		FROM InventoryTransaction
		WHERE batch_num = active_batch
			AND transaction_type = 'PREP'
            AND approval_status = 'PENDING';
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

 
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
        RESIGNAL;
    END;
    
    IF active_batch IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'activateBatch [E01] batch number is null';
    END IF;
	
    SELECT COUNT(*)
    INTO v_count
    FROM Batch 
    WHERE batch_num = active_batch;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'activateBatch [E02] batch not found';
	ELSEIF batch_approver IS NULL OR TRIM(batch_approver) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'activateBatch [E03] batch approver is NULL';
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = batch_approver
		AND is_manager = TRUE;
	
	IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'activateBatch [E04] manager not found';
    END IF;
    
    
    START TRANSACTION;

	SELECT batch_status, recipe_num, plan_num, prepared_quantity
    INTO verify_status, batch_recipe, batch_plan, recipe_quantity
    FROM Batch
    WHERE batch_num = active_batch
    FOR UPDATE;
    
    IF verify_status <> 'PENDING' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'activateBatch [E05] batch must be pending before activation';
	ELSEIF batch_recipe IS NULL THEN
 		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'activateBatch [E06] recipe in batch is NULL';
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Recipe
    WHERE recipe_num = batch_recipe
		AND is_active = TRUE;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'activateBatch [E07] active recipe not found';
	ELSEIF recipe_quantity IS NULL OR recipe_quantity <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'activateBatch [E08] Batch\'s recipe quantity is invalid';
	END IF;
    
    SELECT shelflife
    INTO recipe_life
    FROM Recipe
    WHERE recipe_num = batch_recipe;
    
    IF recipe_life IS NULL OR recipe_life <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'activateBatch [E09] invalid shelflife';
	END IF;
    OPEN cur;
    
    read_loop: LOOP
		FETCH cur INTO ingredient_item, needed_quantity;
		IF done THEN
            LEAVE read_loop;
        END IF;
        
        IF ingredient_item IS NULL OR TRIM(ingredient_item) = '' THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E10] ingredient item is NULL';
		END IF;
        
        SELECT COUNT(*)
        INTO v_count
        FROM Item
        WHERE internal_num = ingredient_item;
        
        IF v_count = 0 THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E11] ingredient item not found';
		ELSEIF needed_quantity IS NULL OR needed_quantity <= 0 THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E12] ingredeint quantity is invalid';
        END IF;
        
        SET needed_quantity = needed_quantity * recipe_quantity;
        
        SELECT COALESCE(SUM(it.quantity),0)
        INTO prep_quantity
        FROM InventoryTransaction as it JOIN Product as p
        ON it.product_num = p.product_num
        WHERE p.internal_num = ingredient_item
			AND it.batch_num = active_batch
            AND it.transaction_type = 'PREP'
            AND it.approval_status = 'PENDING';
		
        IF prep_quantity <> needed_quantity THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E13] Product allocations do not meet ingredient quantity required';
		END IF;
        
	END LOOP;
    CLOSE cur;
    SET done = FALSE;
    
    
    OPEN cur_prep;
    prep_loop: LOOP
		FETCH cur_prep INTO 
			prep_transaction, prep_product, prep_quantity, transaction_creator;
        IF done THEN
			LEAVE prep_loop;
        END IF;
        IF prep_transaction IS NULL THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E14] prep transaction number invalid';
		END IF;
        
        SELECT COUNT(*)
        INTO v_count
        FROM InventoryTransaction
        WHERE transaction_num = prep_transaction;
        
        IF v_count = 0 THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E15] prep transaction not found';
        ELSEIF prep_product IS NULL THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E16] product prepared is NULL';
		ELSEIF transaction_creator IS NULL OR TRIM(transaction_creator) = '' THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E17] prep transaction creator is NULL';
		END IF;
        
		SELECT COUNT(*) 
        INTO v_count 
        FROM Employee 
        WHERE employee_num = transaction_creator;
        
        IF v_count = 0 THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E18] prep transaction creator not found';
		END IF;
        
        SELECT COUNT(*)
        INTO v_count
        FROM ProductInventory
        WHERE product_num = prep_product;
        
        IF v_count = 0 THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E19] Product transaction has invalid product';
		ELSEIF prep_quantity IS NULL OR prep_quantity <= 0 THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E20] Product allocation quantity is invalid';
		END IF;
        
        SELECT quantity 
        INTO current_inventory
        FROM ProductInventory
        WHERE product_num = prep_product
        FOR UPDATE;
        
        IF current_inventory IS NULL OR current_inventory < 0 THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E21] ProductInventory has invalid quantity';
		END IF;	
        
        SET current_inventory = current_inventory - prep_quantity;
        
        IF current_inventory < 0 THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E22] Not enough product for batch allocation';
		END IF;
        
        UPDATE ProductInventory
        SET quantity = current_inventory
        WHERE product_num = prep_product;
        
        UPDATE InventoryTransaction
        SET approval_status = 'APPROVED',
			 approved_by = batch_approver
		WHERE transaction_num = prep_transaction;
    END LOOP;
    CLOSE cur_prep;
    
    
    UPDATE Batch
    SET created_on = CURRENT_TIMESTAMP,
		batch_status = 'ACTIVE',
        expires_at = DATE_ADD(CURRENT_TIMESTAMP, INTERVAL recipe_life HOUR)
	WHERE batch_num = active_batch;
    
    IF batch_plan IS NOT NULL THEN
		SELECT COUNT(*)  
        INTO v_count
        FROM PrepPlan
        WHERE plan_num = batch_plan;
        
        IF v_count = 0 THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'activateBatch [E23] plan num is not NULL and not found';
		END IF;
        
		UPDATE PrepPlan
        SET plan_status = 'COMPLETED'
        WHERE plan_num = batch_plan;
    END IF;
    COMMIT;
END$$

SHOW ERRORS;
DELIMITER ;