DROP PROCEDURE IF EXISTS resolveInventoryTransaction;
DROP PROCEDURE IF EXISTS resolveInvoice;
DROP PROCEDURE IF EXISTS createUseTransaction;
DROP PROCEDURE IF EXISTS createAdjustTransaction;
DROP PROCEDURE IF EXISTS createWasteTransaction;
DELIMITER $$


CREATE PROCEDURE resolveInvoice(
    IN p_invoice_num VARCHAR(20),		-- invoice num to resolve
    IN p_approval_status VARCHAR(20),	-- resolution to invoice
    IN p_approved_by VARCHAR(20)		-- manager num who is resolving
)
BEGIN
    DECLARE v_count INT DEFAULT 0;		
    DECLARE v_old_status VARCHAR(20);	-- previous status of invoice
    DECLARE v_internal_num VARCHAR(20);	-- holds internal nums of all items being updated
    DECLARE v_transaction_num INT;		-- transaction numbers connected to invoice
    DECLARE v_transaction_quantity DECIMAL(10,3);
    DECLARE v_inventory_quantity DECIMAL(10,3);
    DECLARE done INT DEFAULT FALSE;

    DECLARE cur CURSOR FOR				-- gets transaction info for transactions of selected invoice
        SELECT transaction_num, internal_num, quantity
        FROM InventoryTransaction
        WHERE invoice_num = p_invoice_num
          AND transaction_type = 'RECEIVE'
          AND approval_status = 'PENDING';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

	-- Ensures invoice num is given
    SELECT COUNT(*)
    INTO v_count
    FROM Invoice
    WHERE invoice_num = p_invoice_num;
    
	IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid invoice number';

	-- Ensures valid approval state is being set
    ELSEIF p_approval_status NOT IN ('APPROVED','DENIED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Updated invoice must be APPROVED or DENIED';
    END IF;

	-- Ensures valid manager number is given
    SELECT COUNT(*)
    INTO v_count
    FROM Manager
    WHERE manager_num = p_approved_by;
	
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Valid manager credentials are necessary to accept invoice';
    END IF;

    /* lock the invoice row */
    SELECT approval_status
    INTO v_old_status
    FROM Invoice
    WHERE invoice_num = p_invoice_num
    FOR UPDATE;
    
	-- Ensures the invoice is in valid pending state to update
    IF v_old_status <> 'PENDING' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No pending invoice found';
    END IF;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO v_transaction_num, v_internal_num, v_transaction_quantity;

        IF done THEN
            LEAVE read_loop;
        END IF;

		-- invoice aproval must update inventory
        IF p_approval_status = 'APPROVED' THEN
            INSERT INTO Inventory (internal_num, quantity)
            VALUES (v_internal_num, 0)
            ON DUPLICATE KEY UPDATE internal_num = internal_num;

            SELECT quantity
            INTO v_inventory_quantity
            FROM Inventory
            WHERE internal_num = v_internal_num
            FOR UPDATE;

            UPDATE Inventory
            SET quantity = v_inventory_quantity + v_transaction_quantity
            WHERE internal_num = v_internal_num;
        END IF;
		
        -- updates inventoryTransaction's
        UPDATE InventoryTransaction
        SET approval_status = p_approval_status,
            approved_by = p_approved_by
        WHERE transaction_num = v_transaction_num;
    END LOOP;

    CLOSE cur;

	-- updates the invoice
    UPDATE Invoice
    SET approval_status = p_approval_status,
        approved_by = p_approved_by
    WHERE invoice_num = p_invoice_num;

    COMMIT;
END$$


-- Used to resolved single inventory transactions
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
    DECLARE v_transaction_item VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_new_status NOT IN ('APPROVED', 'DENIED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory transaction must be resolved as APPROVED or DENIED';
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM InventoryTransaction
    WHERE transaction_num = p_transaction_num;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction not found';
    END IF;

    SELECT approval_status, transaction_type, internal_num, quantity
    INTO v_old_status, v_transaction_type, v_transaction_item, v_transaction_quantity
    FROM InventoryTransaction
    WHERE transaction_num = p_transaction_num
    FOR UPDATE;

    IF v_old_status <> 'PENDING' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Resolved transactions cannot be updated';
    END IF;

    IF v_transaction_type = 'RECEIVE' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RECEIVE transactions must be resolved through invoice approval';
    END IF;

    IF v_transaction_type <> 'USE' THEN
        SELECT COUNT(*)
        INTO v_count
        FROM Manager
        WHERE manager_num = p_approved_by;

        IF v_count = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid manager credentials for non-USE transaction';
        END IF;
    END IF;

    IF p_new_status = 'APPROVED' THEN
        INSERT INTO Inventory (internal_num, quantity)
        VALUES (v_transaction_item, 0)
        ON DUPLICATE KEY UPDATE internal_num = internal_num;

        SELECT quantity
        INTO v_inventory_quantity
        FROM Inventory
        WHERE internal_num = v_transaction_item
        FOR UPDATE;

        IF v_transaction_type IN ('WASTE', 'USE') THEN
            SET v_inventory_quantity = v_inventory_quantity - v_transaction_quantity;

        ELSEIF v_transaction_type = 'ADJUST' THEN
            SET v_inventory_quantity = v_inventory_quantity + v_transaction_quantity;
        END IF;

        IF v_inventory_quantity < 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Transaction cannot make inventory negative';
        END IF;

        UPDATE Inventory
        SET quantity = v_inventory_quantity
        WHERE internal_num = v_transaction_item;
    END IF;

    IF v_transaction_type = 'USE' THEN
        UPDATE InventoryTransaction
        SET approval_status = p_new_status
        WHERE transaction_num = p_transaction_num;
    ELSE
        UPDATE InventoryTransaction
        SET approval_status = p_new_status,
            approved_by = p_approved_by
        WHERE transaction_num = p_transaction_num;
    END IF;

    COMMIT;
END$$



CREATE PROCEDURE createUseTransaction( 
    IN item VARCHAR(20), 
    IN quantity DECIMAL(10,3), 
    IN manager VARCHAR(20),
    IN product_num VARCHAR(64)
)
BEGIN
    DECLARE v_count INT;
    DECLARE v_price DECIMAL(10,3);
    DECLARE trans_product_num VARCHAR(64);
    DECLARE item_verification VARCHAR(20);
    DECLARE v_conversion DECIMAL(10,3);

    SELECT COUNT(*)
    INTO v_count
    FROM Manager
    WHERE manager_num = manager;
    
    -- ensures quantity is not 0 or negative for use
    IF quantity <= 0 OR quantity IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity for use must be strictly positive';
    -- if manager number is given, ensures it is valid
    ELSEIF v_count = 0 AND manager IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Manager number is invalid';
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Item 
    WHERE internal_num = item;
    
    -- ensures transaction is occurring on an item in the database
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Item number is invalid';
    END IF;
    
    -- if no product num or NULL is given, uses average price
    IF product_num IS NULL OR TRIM(product_num) = '' THEN
        SELECT average_price 
        INTO v_price 
        FROM Item
        WHERE internal_num = item;
        
        SET trans_product_num = NULL;
    ELSE 
        SELECT COUNT(*)
        INTO v_count
        FROM Product
        WHERE vendor_pnum = product_num;

        -- ensures valid product number
        IF v_count = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Product number is invalid';
        END IF;
    
        SELECT internal_num
        INTO item_verification
        FROM Product
        WHERE vendor_pnum = product_num;
    
        -- ensures that internal item matches product number
        IF item_verification <> item THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Vendor product number does not match internal number given';
        END IF;

        SELECT price, conversion_factor
        INTO v_price, v_conversion
        FROM Product
        WHERE vendor_pnum = product_num;
        
        -- ensures that conversion factor is positive
        IF v_conversion <= 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid conversion factor';
        -- ensures that product price is positive
        ELSEIF v_price <= 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid product price';
        END IF;
        
        SET v_price = v_price / v_conversion;
        SET trans_product_num = product_num;
    END IF;

    INSERT INTO InventoryTransaction (
        internal_num,
        transaction_type,
        quantity,
        transaction_date,
        approved_by,
        approval_status,
        invoice_num,
        price_per_unit,
        vendor_pnum,
        reason        
    )
    VALUES (
        item,
        'USE',
        quantity,
        CURRENT_TIMESTAMP,
        manager,
        'PENDING',
        NULL,
        v_price,
        trans_product_num,
        NULL
    );
END $$

CREATE PROCEDURE createAdjustTransaction( 
    IN item VARCHAR(20), 
    IN trans_quantity DECIMAL(10,3), 
    IN manager VARCHAR(20),
    IN adjust_reason VARCHAR(64),
    IN product_num VARCHAR(64)
)
BEGIN
    DECLARE v_count INT;
    DECLARE item_verification VARCHAR(20);
    DECLARE v_price DECIMAL(10,3);
    DECLARE v_conversion DECIMAL(10,3);
    DECLARE trans_product_num VARCHAR(64);
    
    SELECT COUNT(*)
    INTO v_count
    FROM Manager
    WHERE manager_num = manager;
    
    -- ensures quantity is not 0
    IF trans_quantity = 0 OR trans_quantity IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Adjustment quantity cannot be zero';
    -- ensures manager number is valid
    ELSEIF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Manager number is invalid';
    -- ensures reason is given
    ELSEIF adjust_reason IS NULL OR TRIM(adjust_reason) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Adjustments to inventory must have a reason';    
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Item
    WHERE internal_num = item;
    
    -- ensures transaction is occurring on valid item
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid item number';        
    END IF;
    
    -- if product num is not given, uses average price
    IF product_num IS NULL OR TRIM(product_num) = '' THEN
        SELECT average_price
        INTO v_price
        FROM Item
        WHERE internal_num = item;

        SET trans_product_num = NULL;
    -- otherwise verifies product number is for item and uses that price
    ELSE 
        SELECT COUNT(*)
        INTO v_count
        FROM Product
        WHERE vendor_pnum = product_num;
        
        IF v_count = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid product number';    
        END IF;
        
        SELECT internal_num
        INTO item_verification
        FROM Product
        WHERE vendor_pnum = product_num;
    
        -- ensures internal number matches product number
        IF item_verification <> item THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Vendor product number does not match internal number given';
        END IF;
        
        SELECT price, conversion_factor
        INTO v_price, v_conversion
        FROM Product
        WHERE vendor_pnum = product_num;
        
        -- ensures conversion factor is positive 
        IF v_conversion <= 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid conversion factor';
        END IF;
        
        SET v_price = v_price / v_conversion;
        SET trans_product_num = product_num;
    END IF;
    
    INSERT INTO InventoryTransaction (
        internal_num,
        transaction_type,
        quantity,
        transaction_date,
        approved_by,
        approval_status,
        invoice_num,
        vendor_pnum,
        price_per_unit,
        reason
    )
    VALUES (
        item,
        'ADJUST',
        trans_quantity,
        CURRENT_TIMESTAMP,
        manager,
        'PENDING',
        NULL,
        trans_product_num,
        v_price,
        adjust_reason
    );
END $$

CREATE PROCEDURE createWasteTransaction(
    IN item VARCHAR(20),
    IN trans_quantity DECIMAL(10,3),
    IN manager VARCHAR(20),
    IN waste_reason VARCHAR(64),
    IN product_num VARCHAR(64)
)
BEGIN
    DECLARE v_count INT;
    DECLARE item_verification VARCHAR(20);
    DECLARE v_price DECIMAL(10,3);
    DECLARE v_conversion DECIMAL(10,3);
    DECLARE trans_product_num VARCHAR(64);
    
    SELECT COUNT(*)
    INTO v_count
    FROM Item
    WHERE internal_num = item;
    
    IF trans_quantity <= 0 OR trans_quantity IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Waste entry must have quantity greater than 0';
    ELSEIF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid item number for waste transaction';
    ELSEIF waste_reason IS NULL OR TRIM(waste_reason) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Waste entry must have a reason';
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Manager
    WHERE manager_num = manager;
    
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Manager number is invalid';
    END IF;
    
    -- if product num is null or empty use average_price
    IF product_num IS NULL OR TRIM(product_num) = '' THEN
        SELECT average_price
        INTO v_price
        FROM Item
        WHERE internal_num = item;
        
        IF v_price < 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Price must be positive';
        END IF;

        SET trans_product_num = NULL;
    ELSE 
        SELECT COUNT(*) 
        INTO v_count
        FROM Product
        WHERE vendor_pnum = product_num;
        
        -- checking that product number is valid
        IF v_count = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid product number';
        END IF;
        
        SELECT internal_num, price, conversion_factor
        INTO item_verification, v_price, v_conversion
        FROM Product
        WHERE vendor_pnum = product_num;
        
        -- checks to make sure item and product number agree
        IF item_verification <> item THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Vendor product number does not match internal item number';
        -- checks to make sure product price is positive
        ELSEIF v_price <= 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid product price';
        -- checks to make sure conversion factor is positive
        ELSEIF v_conversion <= 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid conversion factor';    
        END IF;
        
        SET v_price = v_price / v_conversion;
        SET trans_product_num = product_num;
    END IF;
    
    INSERT INTO InventoryTransaction(
        internal_num,
        transaction_type,
        quantity,
        transaction_date,
        approved_by,
        approval_status,
        invoice_num,
        reason,
        vendor_pnum,
        price_per_unit
    )
    VALUES (
        item,
        'WASTE',
        trans_quantity,
        CURRENT_TIMESTAMP,
        manager,
        'PENDING',
        NULL,
        waste_reason,
        trans_product_num,
        v_price
    );
END $$

CREATE PROCEDURE addItem(
	IN new_id VARCHAR(20),
    IN new_name VARCHAR(64),
    IN new_category VARCHAR(64),
    IN new_unit VARCHAR(20),
    IN new_price DECIMAL(10,3)
)
BEGIN
	DECLARE v_count INT;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Item
    WHERE internal_num = new_id;
    
	-- verifies that new is not already in Item
    IF v_count <> 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'internal item already taken';
        
	-- verifies name is given
	ELSEIF new_name IS NULL OR TRIM(new_name) = '' THEN
		 SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'item name is required';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Category 
    WHERE category_name = new_category;
    
    -- verifies valid category
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invalid category';
        
	-- verifies item has a unit
	ELSEIF new_unit IS NULL OR TRIM(new_unit) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'internal unit is required';
        
	ELSEIF new_price IS NULL OR new_price <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'strictly positive price is required for new item';	
	END IF;
    
    INSERT INTO Item(
		internal_num,
        internal_name,
        category,
        internal_unit,
        average_price
	)
	VALUES (
		new_id,
        new_name,
        new_category,
        new_unit,
        new_price
	);
END $$

DELIMITER ;