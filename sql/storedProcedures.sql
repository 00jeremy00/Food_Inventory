DROP PROCEDURE IF EXISTS enter_waste;
DROP PROCEDURE IF EXISTS use_product;
DROP PROCEDURE IF EXISTS adjust_inventory;
DROP PROCEDURE IF EXISTS receive_product;
DROP PROCEDURE IF EXISTS updateInventoryTransaction;
DELIMITER $$

CREATE PROCEDURE updateInvoice(
	IN p_invoice_num VARCHAR(20),
    IN p_new_status VARCHAR(20),
    IN p_approved_by VARCHAR(20)
)
BEGIN
	DECLARE v_count INT;
	DECLARE v_old_status VARCHAR(20);
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    IF p_approved_by IS NULL
    OR TRIM(p_approved_by) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Must have valid manager approval';
	
    ELSEIF p_invoice_num IS NULL OR TRIM(p_invoice_num) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Invoice number';		
        
	ELSEIF p_new_status NOT IN ('APPROVED','DENIED') THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Updated invoice must be APPROVED OR DENIED';
    END IF;
    
    START TRANSACTION;
    SELECT approval_status, COUNT(*)
    INTO v_old_status, v_count
    FROM Invoice
    WHERE invoice_num = p_invoice_num;
    
    IF v_old_status <> 'PENDING' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Can only update pending invoice';
	ELSEIF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invoice not found';
	END IF;

    UPDATE Invoice
    SET approval_status = p_new_status
    WHERE invoice_num = p_invoice_num;
    
    UPDATE InvoiceLine
    SET approval_status = p_new_status,
		approved_by = p_approved_by
    WHERE invoice_num = p_invoice_num
    AND approval_status = 'PENDING';
    COMMIT;

END $$

CREATE PROCEDURE updateInventoryTransaction(
    IN p_transaction_num INT,
    IN p_new_status VARCHAR(20)
)
BEGIN
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