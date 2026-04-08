DROP PROCEDURE IF EXISTS resolveInventoryTransaction;
DROP PROCEDURE IF EXISTS createUseTransaction;
DROP PROCEDURE IF EXISTS createAdjustTransaction;
DROP PROCEDURE IF EXISTS createWasteTransaction;
DROP PROCEDURE IF EXISTS createPrepTransaction;
SHOW ERRORS;

DELIMITER $$

CREATE PROCEDURE resolveInventoryTransaction(
    IN p_transaction_num INT,
    IN p_new_status VARCHAR(20),
    IN p_approved_by VARCHAR(20)
)
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_old_status VARCHAR(20);
    DECLARE v_inventory_quantity DECIMAL(10,3);
    DECLARE v_transaction_quantity DECIMAL(10,3);
    DECLARE v_transaction_type VARCHAR(20);
    DECLARE v_transaction_product INT;
    DECLARE v_creator VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

	-- Ensures that resolution status is aprroved or denied
    IF p_new_status NOT IN ('APPROVED', 'DENIED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory transaction must be resolved as APPROVED or DENIED';
	
    -- ensures that valid transaction number was given
	ELSEIF p_transaction_num IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Transaction Number chosen for resolution';  
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM InventoryTransaction
    WHERE transaction_num = p_transaction_num;

	-- makes sure transactionn number matches transaction
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction not found';
	-- ensures that approval is valid and employee num refers to a manager
	ELSEIF p_approved_by IS NULL OR TRIM(p_approved_by) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid approval credentials';
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Employee 
    WHERE employee_num = p_approved_by
    AND is_manager = TRUE;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No manager found matching approver credentials';
	END IF;

    START TRANSACTION;
    
    SELECT approval_status, transaction_type, product_num, quantity, created_by
    INTO v_old_status, v_transaction_type, v_transaction_product, v_transaction_quantity, v_creator
    FROM InventoryTransaction
    WHERE transaction_num = p_transaction_num
    FOR UPDATE;

	SELECT COUNT(*) 
    INTO v_count
    FROM Employee
    WHERE employee_num = v_creator;
    
    -- enures tranaction has a valid creator
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction does not have a valid creator';
	END IF;

	-- enure transaction has not already been resolved
    IF v_old_status <> 'PENDING' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Resolved transactions cannot be updated';
    END IF;

	SELECT COUNT(*) 
    INTO v_count
    FROM Product
    WHERE product_num = v_transaction_product;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Transaction product number';
    END IF;

	-- verfies that transaction type is valid
    IF v_transaction_type = 'RECEIVE' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RECEIVE transactions must be resolved through invoice approval';
	ELSEIF v_transaction_type NOT IN ('WASTE', 'USE', 'ADJUST') THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid transaction type';
    END IF;
    
    IF v_transaction_quantity < 0 AND v_transaction_type <> 'ADJUST' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction quantity can only be negative for ADJUST transactions';	
	END IF;
    
    IF p_new_status = 'APPROVED' THEN
		-- ensures that inventory record exists for product
        INSERT INTO ProductInventory (product_num, quantity)
        VALUES (v_transaction_product, 0)
		ON DUPLICATE KEY UPDATE quantity = ProductInventory.quantity;
        
        SELECT quantity
        INTO v_inventory_quantity
        FROM ProductInventory
        WHERE product_num = v_transaction_product
        FOR UPDATE;

		-- calculates new inventory number after change
        IF v_transaction_type IN ('WASTE', 'USE') THEN
            SET v_inventory_quantity = v_inventory_quantity - v_transaction_quantity;

        ELSEIF v_transaction_type = 'ADJUST' THEN
            SET v_inventory_quantity = v_inventory_quantity + v_transaction_quantity;
        END IF;

		-- ensure new inventory quantity is not negative
        IF v_inventory_quantity < 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Transaction cannot make inventory negative';
        END IF;

        UPDATE ProductInventory
        SET quantity = v_inventory_quantity
        WHERE product_num = v_transaction_product;
    END IF;

	UPDATE InventoryTransaction
	SET approval_status = p_new_status,
		approved_by = p_approved_by
	WHERE transaction_num = p_transaction_num;

    COMMIT;
END$$

CREATE PROCEDURE createUseTransaction( 
    IN use_product INT, 
    IN use_quantity DECIMAL(10,3), 
    IN creator VARCHAR(20)
)
BEGIN
    DECLARE v_count INT;
    DECLARE v_price DECIMAL(10,3);
    DECLARE v_conversion DECIMAL(10,3);
	
    IF creator IS NULL OR TRIM(creator) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory Tranactions must have creator';
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = creator;
    
    -- ensures quantity is not 0 or negative for use
    IF use_quantity <= 0 OR use_quantity IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity for use must be strictly positive';
    -- if manager number is given, ensures it is valid
    ELSEIF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee number is invalid';
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Product 
    WHERE product_num = use_product;
    
    -- ensures transaction is occurring on an item in the database
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product number does not match valid product';
    END IF;

	SELECT price, conversion_factor
	INTO v_price, v_conversion
	FROM Product
	WHERE product_num = use_product;
        
	-- ensures that conversion factor is positive
	IF v_conversion <= 0 OR v_conversion IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Invalid conversion factor';
	-- ensures that product price is positive
	ELSEIF v_price <= 0 OR v_price IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Invalid product price';
	END IF;
        
	SET v_price = v_price / v_conversion;

    INSERT INTO InventoryTransaction (
        transaction_type,
        quantity,
        transaction_date,
        created_by,
        approval_status,
        price_per_unit,
        product_num       
    )
    VALUES (
        'USE',
        use_quantity,
        CURRENT_TIMESTAMP,
        creator,
        'PENDING',
        v_price,
        use_product
    );
END $$

CREATE PROCEDURE createAdjustTransaction( 
    IN adjust_product INT, 
    IN trans_quantity DECIMAL(10,3), 
    IN creator VARCHAR(20),
    IN adjust_reason VARCHAR(64)
)
BEGIN
    DECLARE v_count INT;
    DECLARE v_price DECIMAL(10,3);
    DECLARE v_conversion DECIMAL(10,3);

	-- Verifies that product number is not NULL
	IF adjust_product IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product number needed for adjustment';
	END IF;
    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = creator;
    
    -- ensures quantity is not 0
    IF trans_quantity = 0 OR trans_quantity IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Adjustment quantity cannot be zero';
    -- ensures manager number is valid
    ELSEIF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee number is invalid';
    -- ensures reason is given
    ELSEIF adjust_reason IS NULL OR TRIM(adjust_reason) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Adjustments to inventory must have a reason';    
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Product
    WHERE product_num = adjust_product;
    
    -- ensures transaction is occurring on valid product
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid product number';        
    END IF;
    
        
        
	SELECT price, conversion_factor
	INTO v_price, v_conversion
	FROM Product
	WHERE product_num = adjust_product;
        
	-- ensures conversion factor and product price are positive 
	IF v_conversion <= 0 OR v_conversion IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Invalid conversion factor';
	ELSEIF v_price <= 0 OR v_price IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Invalid product price';
	END IF;
        
	SET v_price = v_price / v_conversion;
    
    INSERT INTO InventoryTransaction (
        transaction_type,
        quantity,
        transaction_date,
        created_by,
        approval_status,
        invoice_id,
        product_num,
        price_per_unit,
        reason
    )
    VALUES (
        'ADJUST',
        trans_quantity,
        CURRENT_TIMESTAMP,
        creator,
        'PENDING',
        NULL,
        adjust_product,
        v_price,
        TRIM(adjust_reason)
    );
END $$

CREATE PROCEDURE createWasteTransaction(
    IN waste_product INT,
    IN trans_quantity DECIMAL(10,3),
    IN creator VARCHAR(20),
    IN waste_reason VARCHAR(64)
)
BEGIN
    DECLARE v_count INT;
    DECLARE v_price DECIMAL(10,3);
    DECLARE v_conversion DECIMAL(10,3);
    
    -- verifies product being wasted is not null
    IF waste_product IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction requires valid product';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Product
    WHERE product_num = waste_product;
    
    -- verifies transaction quantity is strictly positive and not NULL
    IF trans_quantity <= 0 OR trans_quantity IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Waste entry must have quantity greater than 0';
    
    -- verifies procut number refers to a valid product
    ELSEIF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid product number for waste transaction';
    ELSEIF waste_reason IS NULL OR TRIM(waste_reason) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Waste entry must have a reason';
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = creator;
    
    -- enure creator is a valid employee
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee number is invalid';
    END IF;
    
        
	SELECT price, conversion_factor
	INTO v_price, v_conversion
	FROM Product
	WHERE product_num = waste_product;
        
	-- checks to make sure price is strictly positive and not NULL
	IF v_price <= 0 OR v_price IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Invalid product price';
	-- checks to make sure conversion factor is positive
	ELSEIF v_conversion <= 0 OR v_conversion IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Invalid conversion factor';    
	END IF;
        
	SET v_price = v_price / v_conversion;
    
    INSERT INTO InventoryTransaction(
        transaction_type,
        quantity,
        transaction_date,
        created_by,
        approval_status,
        invoice_id,
        reason,
        product_num,
        price_per_unit
    )
    VALUES (
        'WASTE',
        trans_quantity,
        CURRENT_TIMESTAMP,
        creator,
        'PENDING',
        NULL,
        TRIM(waste_reason),
        waste_product,
        v_price
    );
END $$

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
END $$

DELIMITER;