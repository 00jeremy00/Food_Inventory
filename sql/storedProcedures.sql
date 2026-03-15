DROP PROCEDURE IF EXISTS enter_waste;
DROP PROCEDURE IF EXISTS use_product;
DROP PROCEDURE IF EXISTS adjust_inventory;
DROP PROCEDURE IF EXISTS receive_product;
DROP PROCEDURE IF EXISTS updateInventoryTransaction;
DROP PROCEDURE IF EXISTS resolveInvoice;
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
	DECLARE count INT;
    DECLARE inventory_quantity DECIMAL(10,3);
    DECLARE transaction_quantity DECIMAL(10,3);
    DECLARE trans_type VARCHAR(20);
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;    
    
    SELECT COUNT(*)
    INTO count
    FROM InventoryTransaction
    WHERE transaction_num = p_transaction_num;

	-- Ensures that transaction number is valid
	IF count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction not found';
	END IF;
    
	SELECT COUNT(*)
    INTO count
    FROM Manager
    WHERE manager_num = p_approved_by;
    
    -- Ensures valid manager credentials are given
	IF count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Manager Credentials';
	END IF;
    
    -- Ensures that final transaction status is valid
    IF p_new_status NOT IN ('APPROVED', 'DENIED') THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invnetory Transaction must be resolved by APPROVED OR DENIED';
	END IF;
    
    -- locks inventorytransaction and gets transaction quantity
	SELECT quantity, transaction_type
    INTO transaction_quantity, trans_type
    FROM InventoryTransaction
    WHERE transaction_num = p_transaction_num
    FOR UPDATE;
    
        -- locks inventory and gets inventory quantity
	SELECT quantity
    INTO inventory_quantity
    FROM Inventory
    WHERE transaction_num = p_transaction_num
    FOR UPDATE;
    
    IF trans_type <> 'USE'
     
    
    
    
    
    
    
	COMMIT;











    DECLARE v_internal_num VARCHAR(20);
    DECLARE v_transaction_type VARCHAR(20);
    DECLARE v_transaction_qty DECIMAL(10,3);
    DECLARE v_old_status VARCHAR(20);
    DECLARE v_current_qty DECIMAL(10,3);
    DECLARE v_result_qty DECIMAL(10,3);

    START TRANSACTION;

    SELECT internal_num,
           transaction_type,
           quantity,
           approval_status
    INTO v_internal_num,
         v_transaction_type,
         v_transaction_qty,
         v_old_status
    FROM InventoryTransaction
    WHERE transaction_num = p_transaction_num
    FOR UPDATE;

    IF v_old_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction not found';
    END IF;

    IF p_new_status NOT IN ('APPROVED', 'DENIED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'New status must be APPROVED or DENIED';
    END IF;

    IF v_old_status IN ('APPROVED', 'DENIED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot update a resolved transaction';
    END IF;

    IF p_new_status = 'DENIED' THEN
        UPDATE InventoryTransaction
        SET approval_status = 'DENIED'
        WHERE transaction_num = p_transaction_num;

        COMMIT;
    ELSE
        INSERT INTO Inventory (internal_num, quantity)
        VALUES (v_internal_num, 0)
        ON DUPLICATE KEY UPDATE internal_num = internal_num;

        SELECT quantity
        INTO v_current_qty
        FROM Inventory
        WHERE internal_num = v_internal_num
        FOR UPDATE;

        IF v_transaction_type  IN ('ADJUST','RECEIVE') THEN
            SET v_result_qty = v_current_qty + v_transaction_qty;

        ELSEIF v_transaction_type IN ('USE', 'WASTE') THEN
            SET v_result_qty = v_current_qty - v_transaction_qty;
            
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid transaction type';
        END IF;

        IF v_result_qty < 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Approval would create negative inventory';
        END IF;

        UPDATE InventoryTransaction
        SET approval_status = 'APPROVED'
        WHERE transaction_num = p_transaction_num;

        UPDATE Inventory
        SET quantity = v_result_qty
        WHERE internal_num = v_internal_num;

        COMMIT;
    END IF;
END$$

CREATE PROCEDURE enter_waste(
    IN trans_num VARCHAR(64), 
    IN item VARCHAR(20), 
    IN quantity DECIMAL(10,3), 
    IN trans_date DATETIME,
    IN manager VARCHAR(20), 
    IN reason VARCHAR(64)
)
BEGIN
    INSERT INTO InventoryTransaction (
        transaction_num,
        internal_num,
        transaction_type,
        quantity,
        transaction_date,
        manager,
        invoice_num,
        reason
    )
    VALUES (
        trans_num,
        item,
        'WASTE',
        quantity,
        trans_date,
        manager,
        NULL,
        reason
    );
END $$


CREATE PROCEDURE use_product(
    IN trans_num VARCHAR(64), 
    IN item VARCHAR(20), 
    IN quantity DECIMAL(10,3), 
    IN trans_date DATETIME,
    IN manager VARCHAR(20) 
)
BEGIN
    INSERT INTO InventoryTransaction (
        transaction_num,
        internal_num,
        transaction_type,
        quantity,
        transaction_date,
        manager,
        invoice_num,
        reason
    )
    VALUES (
        trans_num,
        item,
        'USE',
        quantity,
        trans_date,
        manager,
        NULL,
        NULL
    );
END $$

CREATE PROCEDURE adjust_inventory(
    IN trans_num VARCHAR(64), 
    IN item VARCHAR(20), 
    IN quantity DECIMAL(10,3), 
    IN trans_date DATETIME,
    IN manager VARCHAR(20),
    IN reason VARCHAR(64)
)
BEGIN
    INSERT INTO InventoryTransaction (
        transaction_num,
        internal_num,
        transaction_type,
        quantity,
        transaction_date,
        manager,
        invoice_num,
        reason
    )
    VALUES (
        trans_num,
        item,
        'ADJUST',
        quantity,
        trans_date,
        manager,
        NULL,
        reason
    );
END $$

CREATE PROCEDURE receive_product(
    IN trans_num VARCHAR(64), 
    IN item VARCHAR(20), 
    IN quantity DECIMAL(10,3), 
    IN trans_date DATETIME,
    IN manager VARCHAR(20),
    IN invoice VARCHAR(20)
)
BEGIN
    INSERT INTO InventoryTransaction (
        transaction_num,
        internal_num,
        transaction_type,
        quantity,
        transaction_date,
        manager,
        invoice_num,
        reason
    )
    VALUES (
        trans_num,
        item,
        'RECEIVE',
        quantity,
        trans_date,
        manager,
        invoice,
        NULL
    );
END $$

DELIMITER ;