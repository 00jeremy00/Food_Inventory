CREATE TRIGGER prevent_negative_inventory
BEFORE INSERT ON InventoryTransaction
FOR EACH ROW
BEGIN
    DECLARE current_qty DECIMAL(10,3);
	IF NEW.manager_num IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Must have manager credentials';

	ELSEIF NEW.transaction_type IN ('WASTE', 'ADJUST')
    AND (NEW.reason IS NULL OR TRIM(NEW.reason) = '') THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Must have reason for waste or adjustment';
        
	ELSEIF (NEW.quantity <= 0 AND NEW.transaction_type != 'ADJUST') THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Only transaction can have a negative field';
	END IF;

    SELECT quantity
    INTO current_qty
    FROM Inventory
    WHERE internal_num = NEW.internal_num;

	IF current_qty IS NULL THEN
		SET current_qty = 0;
	END IF;

    IF NEW.transaction_type IN ('USE','WASTE') 
       AND current_qty - NEW.quantity < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory cannot go negative';
        
	ELSEIF NEW.transaction_type = 'ADJUST'
		AND current_qty + NEW.quantity < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory cannot go negative';

    END IF;

END $$

CREATE TRIGGER update_inventory
AFTER INSERT ON InventoryTransaction
FOR EACH ROW
BEGIN
	DECLARE current_quantity DECIMAL(10,3);
	IF EXISTS (
		SELECT 1 FROM Inventory
        WHERE internal_num = NEW.internal_num
    ) THEN
		SELECT quantity 
		INTO current_quantity
		FROM Inventory 
		WHERE NEW.internal_num = internal_num;
		IF NEW.transaction_type = 'ADJUST' THEN
			SET current_quantity = current_quantity + NEW.quantity;
            
		ELSEIF NEW.transaction_type = 'RECEIVE' THEN
			SET current_quantity = current_quantity + ABS(NEW.quantity);
            
		ELSEIF NEW.transaction_type IN ('WASTE', 'USE') THEN 
            SET current_quantity = current_quantity - ABS(NEW.quantity);
		END IF;
        IF current_quantity < 0 THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Inventory cannot go negative';
		
        ELSE
			UPDATE Inventory
			SET quantity = current_quantity
			WHERE internal_num = NEW.internal_num;
		END IF;
    ELSE 
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "Cannot use or waste product not in inventory";
	END IF;
END $$



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
        WHERE internal_num = NEW.internal_num;
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