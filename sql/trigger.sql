DROP TRIGGER IF EXISTS validate_invoice_update;
DROP TRIGGER IF EXISTS validate_inventory_transaction_update;
DROP TRIGGER IF EXISTS populate_inventory;

DELIMITER $$

CREATE TRIGGER populate_inventory
AFTER INSERT ON Product
FOR EACH ROW
BEGIN
		INSERT INTO ProductInventory (product_num, quantity)
		VALUES (NEW.product_num, 0)
		ON DUPLICATE KEY UPDATE product_num = product_num;
END $$
 

DELIMITER ;

SHOW TRIGGERS;