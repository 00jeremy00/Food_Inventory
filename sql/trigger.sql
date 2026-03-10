DROP TRIGGER IF EXISTS prevent_negative_inventory;
DROP TRIGGER IF EXISTS update_inventory;

DELIMITER $$

CREATE TRIGGER prevent_negative_inventory
BEFORE INSERT ON InventoryTransaction
FOR EACH ROW
BEGIN

    DECLARE current_qty DECIMAL(10,3);

    SELECT quantity
    INTO current_qty
    FROM Inventory
    WHERE internal_num = NEW.internal_num;

	IF current_qty IS NULL THEN
		SET current_qty = 0;
	END IF;

    IF NEW.transaction_type IN ('USE','WASTE') 
       AND current_qty - ABS(NEW.quantity) < 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory cannot go negative';

    END IF;

END $$

CREATE TRIGGER update_inventory
AFTER INSERT ON InventoryTransaction
FOR EACH ROW
BEGIN
	IF EXISTS (
		SELECT 1 FROM Inventory
        WHERE internal_num = NEW.internal_num
    ) THEN
		IF NEW.transaction_type =  'ADJUST' THEN
			UPDATE Inventory
            SET quantity = abs(NEW.quantity)
            WHERE internal_num = NEW.internal_num;
            
		ELSEIF NEW.transaction_type = 'RECEIVE' THEN 
			UPDATE Inventory
            SET quantity = quantity + abs(NEW.quantity)
            WHERE internal_num = NEW.internal_num;
		
        ELSE 
			UPDATE Inventory
            SET quantity = quantity - abs(NEW.quantity)
			WHERE internal_num = NEW.internal_num;
		END IF;
	ELSE
		INSERT INTO Inventory(internal_num, quantity)
        VALUES (NEW.internal_num, abs(NEW.quantity));
	END IF;
END $$
DELIMITER ;