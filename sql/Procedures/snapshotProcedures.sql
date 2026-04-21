DROP PROCEDURE IF EXISTS createInventorySnapshotRecord;
DROP PROCEDURE IF EXISTS createProductSnapshot;
DROP PROCEDURE IF EXISTS completeSnapshot;
DROP PROCEDURE IF EXISTS createRecipeSnapshot;
DELIMITER $$

CREATE PROCEDURE createInventorySnapshotRecord(
	IN recorder VARCHAR(20)
)
BEGIN
    DECLARE v_count INT;

    -- verifies snapshot recorder has valid employee num
    IF recorder IS NULL OR TRIM(recorder) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT ='invalid employee number for snapshot record' ;
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = recorder
    AND is_manager = TRUE;

    -- Verifies recorder credentials match a manager in Employees
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No manager found matching recorder number' ;
    END IF;

    INSERT INTO InventorySnapshotRecord(
        snapshot_time,
        previous_snapshot,
        snapshot_status,
        recorded_by
) VALUES (
        CURRENT_TIMESTAMP,
        last_snapshot,
        'PENDING',
        recorder
);
END$$

CREATE PROCEDURE createProductSnapshot(
    IN inventory_snapshot INT,
    IN inventory_product INT,
    IN counted_total DECIMAL(10,3)
)
BEGIN
    DECLARE v_count INT;
    DECLARE expected_total DECIMAL(10,3);
    DECLARE last_snapshot INT;
    DECLARE last_count DECIMAL(10,3);

	-- verifies none of inputs are NULL and counted_quantity is not negative
    IF inventory_snapshot IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory Snapshot Record required for Inventory Snapshot' ;
	ELSEIF inventory_product IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product Number required for Inventory Snapshot' ;    
	ELSEIF counted_total IS NULL OR  counted_quantity < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Counted quantity is invalid' ;
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM InventorySnapshotRecord
    WHERE snapshot_id = inventory_snapshot
		AND snapshot_status = 'PENDING';

	-- verififes that the snapshot record exists
	IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No PENDING snapshot id found';
	END IF;
    
    -- Makes sure that product entry for snapshotInventory is a valid product
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Snapshot product not found in Products';
	END IF;
    
    
    -- ensures product inventory exists and is valid
    SELECT COUNT(*) 
    INTO v_count
    FROM ProductInventory
    WHERE product_num = inventory_product;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No product inventory found';
	END IF;
    
    SELECT quantity 
    INTO expected_total
    FROM ProductInventory
    WHERE product_num = inventory_product;
    
    IF expected_total IS NULL OR expected_total < 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product inventory invalid';
	END IF;
    
    INSERT INTO ProductSnapshot(
		snapshot_id,
		product_num,
		expected_quantity,
		counted_quantity
    ) VALUES (
		inventory_snapshot,
        inventory_product,
        expected_total,
        counted_total
        );
    
END$$

CREATE PROCEDURE createRecipeSnapshot(
	IN snap_id INT,
    IN recipe_snapshot INT,
    IN recipe_count DECIMAL(10,3)
)
BEGIN
	DECLARE v_count INT;
    DECLARE running_total DECIMAL(10,3);
    DECLARE done INT DEFAULT FALSE;
        DECLARE cur CURSOR FOR
		SELECT remaining_quantity
        FROM Batch
        WHERE batch_status = 'ACTIVE'
			AND recipe_num = recipe_snapshot;
            
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
        RESIGNAL;
    END;
    
	IF snap_id IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createRecipeSnapshot [E01] snapshot id is NULL';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM InventorySnapshotRecord
    WHERE snapshot_id = snap_id
		AND snapshot_status = 'PENDING';
        
	IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createRecipeSnapshot [E02] snapshot not found';
	ELSEIF recipe_snapshot IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createRecipeSnapshot [E03] recipe is NULL';
	END IF;

	SELECT COUNT(*)
    INTO v_count
    FROM Recipe
    WHERE recipe_num = recipe_snapshot
		AND recipe_status <> 'PENDING';
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createRecipeSnapshot [E04] recipe not found';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM RecipeSnapshot
    WHERE snapshot_id = snap_id
		 AND recipe_num = recipe_snapshot;
         
	IF v_count > 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createRecipeSnapshot [E05] recipe snapshot already exists';
	END IF;
    
    IF recipe_count IS NULL OR recipe_count < 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createRecipeSnapshot [E06] recipe counted quantity is invalid';
	END IF;
    
    START TRANSACTION;
	SELECT COALESCE(SUM(remaining_quantity), 0)
	INTO running_total
	FROM Batch
	WHERE batch_status = 'ACTIVE'
		AND recipe_num = recipe_snapshot
	FOR UPDATE;
	
    IF running_total < 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createRecipeSnapshot [E07] summation of batch remaining quantities is invalid';
	END IF;
    
        
    INSERT INTO RecipeSnapshot(
    	snapshot_id,
		recipe_num,
		expected_quantity,
		counted_quantity
    ) VALUES(
		snap_id,
        recipe_snapshot,
        running_total,
        recipe_count
    );
    
    COMMIT;
    
END$$

CREATE PROCEDURE completeSnapshot(
	IN completed_snapshot INT
)
BEGIN 
	DECLARE v_count INT;
    DECLARE inventory_product INT;
    DECLARE snap_status VARCHAR(20);
    DECLARE done INT DEFAULT FALSE;
    DECLARE cur CURSOR FOR				-- gets transaction info for transactions of selected invoice
        SELECT product_num
        FROM ProductInventory
        WHERE quantity > 0;

    IF completed_snapshot IS NULL OR completed_snapshot < 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'completeSnapshot [E01]: Invalid snapshot number';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM InventorySnapshotRecord
    WHERE snapshot_id = completed_snapshot;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'completeSnapshot [E02]:Snapshot not found';
	END IF;
    
    SELECT snapshot_status
    INTO snap_status
    FROM InventorySnapshotRecord
    WHERE snapshot_id = completed_snapshot;
    
    -- verifies snapshot is pending
    IF snap_status <> 'PENDING' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'completeSnapshot [E03]:Snapshot must be PENDING to resolve';
	END IF;
    
    -- verifies nonzero product quantity has a snapshot counting that product
    OPEN cur;
    read_loop: LOOP
        FETCH cur 
        INTO inventory_product;
        IF done THEN
            LEAVE read_loop;

        END IF;
        
        SELECT COUNT(*)
        INTO v_count
        FROM InventorySnapshot
        WHERE snapshot_id = completed_snapshot
			AND product_num = inventory_product;
            
		IF v_count = 0 THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'completeSnapshot [E04]:No Snapshot Counting Product with Nonzero Inventory quantity';
		END IF;
	END LOOP;
    CLOSE cur;
    
    UPDATE InventorySnapshotRecord
	SET snapshot_status = 'COMPLETED'
    WHERE snapshot_id = completed_snapshot;
    
END $$

DELIMITER ;