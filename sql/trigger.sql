DELIMITER $$
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
            SET quantity = NEW.quantity
            WHERE internal_num = NEW.internal_num;
            
		ELSE 
			UPDATE Inventory
            SET quantity = quantity + NEW.quantity
            WHERE internal_num = NEW.internal_num;
		END IF;
	ELSE
		INSERT INTO Inventory(internal_num, quantity)
        VALUES (NEW.internal_num, NEW.quantity);
	END IF;
END $$
DELIMITER ;