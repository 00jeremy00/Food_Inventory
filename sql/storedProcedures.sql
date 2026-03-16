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
DROP PROCEDURE IF EXISTS resolveInventoryTransaction;
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
    IN manager VARCHAR(20) 
)
BEGIN
	DECLARE v_count INT;
    
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
        SET MESSAGE_TEXT = 'Manager mumberis invalid';
	END IF;

	SELECT COUNT(*)
    INTO v_count
    FROM Item 
    WHERE internal_num = item;
    
    -- ensures transaction is occuring on an item in the database
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Item number is invalid';
	END IF;
    
    
    INSERT INTO InventoryTransaction (
        internal_num,
        transaction_type,
        quantity,
        transaction_date,
        approved_by,
        approval_status,
        invoice_num,
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
        NULL
    );
END$$

CREATE PROCEDURE createAdjustTransaction( 
    IN item VARCHAR(20), 
    IN trans_quantity DECIMAL(10,3), 
    IN manager VARCHAR(20),
    IN adjust_reason VARCHAR(64)
)
BEGIN
	DECLARE v_count INT;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Manager
    WHERE manager_num = manager;
    
	-- ensures quantity is not 0
	IF trans_quantity = 0 or trans_quantity IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity for use must be strictly positive';
	--  ensures manager number it is valid
	ELSEIF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Manager mumberis invalid';
	-- ensures reason is given
    ELSEIF adjust_reason IS NULL or TRIM(adjust_reason) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Adjustments to inventory must have a reason';	
	END IF;

	SELECT COUNT(*)
    INTO v_count
    FROM Item
    WHERE internal_num = item;
    
    -- ensures transaction is occuring on valid item
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid item number';		
	END IF;
    
   INSERT INTO InventoryTransaction (
        internal_num,
        transaction_type,
        quantity,
        transaction_date,
        approved_by,
        approval_status,
        invoice_num,
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
        adjust_reason
    );
END $$

CREATE PROCEDURE createWasteTransaction(
	IN item VARCHAR(20),
    IN trans_quantity DECIMAL(10,3),
    IN manager VARCHAR(20),
    IN waste_reason VARCHAR(64)
)
BEGIN
	DECLARE v_count INT;
    
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
	ELSEIF waste_reason IS NULL OR TRIM(waste_reason) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Waste entry must have quantity greater than 0';
	END IF;
    
	SELECT COUNT(*)
    INTO v_count
    FROM Manager
    WHERE manager_num = manager;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Manager mumberis invalid';
    END IF;
    
    INSERT INTO InventoryTransaction(
		internal_num,
        transaction_type,
        quantity,
        transaction_date,
        approved_by,
        approval_status,
        invoice_num,
        reason
    )
    VALUES (
        item,
        'WASTE',
        trans_quantity,
        CURRENT_TIMESTAMP,
        manager,
        'PENDING',
        NULL,
        adjust_reason
    );
END $$

DELIMITER ;