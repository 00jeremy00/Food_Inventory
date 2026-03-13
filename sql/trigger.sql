DROP TRIGGER IF EXISTS validate_invoice_update;
DROP TRIGGER IF EXISTS update_invoice_line;
DROP TRIGGER IF EXISTS validate_inventory_transaction_update;
DROP TRIGGER IF EXISTS update_inventory;
DROP TRIGGER IF EXISTS populate_inventory;

DELIMITER $$

CREATE TRIGGER populate_inventory
AFTER INSERT ON Item
FOR EACH ROW
BEGIN
		INSERT INTO Inventory (internal_num, quantity)
		VALUES (NEW.internal_num, 0)
		ON DUPLICATE KEY UPDATE internal_num = internal_num;
END $$

CREATE TRIGGER validate_invoice_update
BEFORE UPDATE ON Invoice
FOR EACH ROW
BEGIN
    IF OLD.approval_status IN ('APPROVED','DENIED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot update a resolved invoice';
	ELSEIF NEW.approved_by IS NULL 
    AND NEW.approval_status IN ('APPROVED', 'DENIED') THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Manager needed to resolve invoice';
    END IF;
END$$

CREATE TRIGGER update_invoice_line
AFTER UPDATE ON Invoice
FOR EACH ROW
BEGIN
    IF OLD.approval_status <> NEW.approval_status THEN
    
        IF NEW.approval_status = 'APPROVED' THEN
            UPDATE InventoryTransaction
            SET approval_status = 'APPROVED'
            WHERE invoice_num = NEW.invoice_num
              AND transaction_type = 'RECEIVE';
    
        ELSEIF NEW.approval_status = 'DENIED' THEN
            UPDATE InventoryTransaction
            SET approval_status = 'DENIED'
            WHERE invoice_num = NEW.invoice_num
              AND transaction_type = 'RECEIVE';
        END IF;
        
    END IF;
END$$

CREATE TRIGGER validate_inventory_transaction_update
BEFORE UPDATE ON InventoryTransaction
FOR EACH ROW
BEGIN
    DECLARE current_quantity DECIMAL(10,3);

    IF OLD.approval_status IN ('APPROVED','DENIED') 
    AND OLD.approval_status = 'PENDING' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot update a Resolved transaction';
	ELSEIF NEW.approved_by IS NULL
    AND NEW.transaction_type <> 'USE' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Manager credentials needed to input not USE transaction';
    END IF;

    IF NEW.approval_status = 'APPROVED' THEN
		INSERT INTO Inventory (internal_num, quantity)
		VALUES (NEW.internal_num, 0)
		ON DUPLICATE KEY UPDATE internal_num = internal_num;
        
        SELECT quantity
        INTO current_quantity
        FROM Inventory
        WHERE internal_num = NEW.internal_num;

        IF NEW.transaction_type IN ('WASTE', 'USE') THEN
            IF current_quantity - NEW.quantity < 0 THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Cannot approve transaction that would create negative inventory';
            END IF;

        ELSEIF NEW.transaction_type = 'ADJUST' THEN
            IF current_quantity + NEW.quantity < 0 THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Cannot approve transaction that would create negative inventory';
            END IF;
        END IF;

    END IF;
END$$

CREATE TRIGGER update_inventory
AFTER UPDATE ON InventoryTransaction
FOR EACH ROW
BEGIN
    DECLARE current_quantity DECIMAL(10,3);
    
	SELECT quantity
	INTO current_quantity
	FROM Inventory
	WHERE internal_num = NEW.internal_num;

	IF OLD.approval_status = 'PENDING'
		AND NEW.approval_status = 'APPROVED' THEN
        
		IF NEW.transaction_type IN ('WASTE', 'USE') THEN
			SET current_quantity = current_quantity - NEW.quantity;
		ELSE
			SET current_quantity = current_quantity + NEW.quantity;
		END IF;
		UPDATE Inventory
        SET quantity = current_quantity
        WHERE internal_num = NEW.internal_num
        AND approval_status = 'PENDING';
	END IF;




END$$

DELIMITER ;

SHOW TRIGGERS;