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
    
	-- verifies that new is not already in Item and valid
    IF new_id IS NULL OR TRIM(new_id) = '' THEN
   		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invalid item number'; 
    ELSEIF v_count <> 0 THEN
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

CREATE PROCEDURE addProduct(
	IN new_product VARCHAR(64),
    IN new_name VARCHAR(255),
    IN new_internal_num VARCHAR(20),
    IN new_unit VARCHAR(20),
    IN new_vendor VARCHAR(6),
    IN new_price DECIMAL(10,2),
    IN new_factor DECIMAL(10,3)
)
BEGIN 
	DECLARE v_count INT;
    
SELECT COUNT(*)
    INTO v_count
    FROM Product
    WHERE vendor_pnum = new_product;
    
	-- verifies product number is valid and not taken
    IF new_product IS NULL OR TRIM(new_product) = '' THEN
   		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invalid item number'; 
    ELSEIF v_count <> 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'internal item already taken';
	END IF;
    
	SELECT COUNT(*)
    INTO v_count
    FROM Item
    WHERE internal_num = new_internal_num;
    
	-- verifies that new item number valid and exists
    IF new_internal_num IS NULL OR TRIM(new_internal_num) = '' THEN
   		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invalid item number'; 
    ELSEIF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'internal does not exist';
        
	-- verifies name is given
	ELSEIF new_name IS NULL OR TRIM(new_name) = '' THEN
		 SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'item name is required';
        
	-- verifies item has a unit
	ELSEIF new_unit IS NULL OR TRIM(new_unit) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'internal unit is required';
	
    -- verifies product has a valid conversion factor
	ELSEIF new_factor IS NULL OR new_factor <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'conversion factor is required';
	
	ELSEIF new_price IS NULL OR new_price <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'strictly positive price is required for new product';	
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Vendor
    WHERE vendor_num = new_vendor;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invalid vendor number';	
	END IF;
    
    INSERT INTO Product(
    	vendor_pnum,
		vendor_pname,
		internal_num,
		purchase_unit,
		vendor_num,
		price,
		conversion_factor
    )
    VALUES(
		new_product,
		new_name,
		new_internal_num,
		new_unit,
		new_vendor,
		new_price,
		new_factor
    );
END $$

CREATE PROCEDURE addVendor(
	IN new_vendor_num VARCHAR(6),
    IN new_name VARCHAR(64),
    IN new_phone_number VARCHAR(20),
    IN new_email VARCHAR(64),
    IN new_website VARCHAR(255)
)
BEGIN
	DECLARE v_count INT;
    SELECT COUNT(*)
    INTO v_count
    FROM Vendor
    WHERE vendor_num = new_vendor_num;
    
    -- enures vendor num is valid
    IF new_vendor_num IS NULL OR TRIM(new_vendor_num) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Vendor requires identifying number';
        
	ELSEIF v_count <> 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Vendor number already taken';
	
    ELSEIF new_name IS NULL OR TRIM(new_name) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'requires vendor name';
    
	END IF;
    INSERT INTO Vendor(
    	vendor_num,
		vendor_name,
		phone_number,
		email,
		website
    ) 
    VALUES(
		new_vendor_num,
        new_name,
        new_phone_number,
        new_email,
        new_website
    );
END $$


CREATE PROCEDURE addManager(
	IN new_manager_num VARCHAR(20),
    IN new_name VARCHAR(64)
)
BEGIN 
	DECLARE v_count INT;
    
    SELECT COUNT(*)
    INTO v_count 
    FROM Manager
    WHERE manager_num = new_manager_num;
    
    IF new_manager_num IS NULL OR TRIM(new_manager_num) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'manager number required';
	ELSEIF v_count <> 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'manager number already taken';
	ELSEIF new_name IS NULL OR TRIM(new_name) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'manager name is required';
	END IF;
    
    INSERT INTO Manager(
		manager_num,
        manager_name
    )
    VALUES(
		new_manager_num,
        new_name
    );
END $$

CREATE PROCEDURE addInvoice(
	IN new_invoice VARCHAR(20),
	IN new_date DATE,
    IN new_vendor VARCHAR(6)
)
BEGIN
	DECLARE v_count INT;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Invoice
    WHERE invoice_num = new_invoice;
    
    -- verifies invoice number is valid
    IF new_invoice IS NULL OR TRIM(new_invoice) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invoice number needed for invoice';
	ELSEIF v_count <> 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invoice number in use';
    END IF;
    
    -- verifies date 
    IF new_date IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invalid date';	
	END IF;
    
	SELECT COUNT(*)
    INTO v_count
    FROM Vendor
    WHERE vendor_num = new_vendor;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invalid vendor number';	
	END IF;
    
    INSERT INTO Invoice(
		invoice_num,
        invoice_date,
        vendor_num,
        approval_status,
        approved_by
    )
    VALUES(
		new_invoice,
        new_date,
        new_vendor,
        'PENDING',
        NULL
    );

END $$

CREATE PROCEDURE addInvoiceLine(
	IN new_invoice VARCHAR(20),
    IN new_product_num VARCHAR(64),
    IN new_quantity DECIMAL(10,3)
)
BEGIN
	DECLARE v_count INT;
    DECLARE new_internal_num VARCHAR(20);
    DECLARE new_product_price DECIMAL(10,3);
    DECLARE invoice_status VARCHAR(20);
    DECLARE product_vendor VARCHAR(6);
    DECLARE invoice_vendor VARCHAR(6);
    DECLARE v_factor DECIMAL(10,3);
    
    
    SELECT COUNT(*)
    INTO v_count
    FROM Invoice
    WHERE invoice_num = new_invoice;
    
    -- verifies invoice number is valid
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invoice not found';
	END IF;
    
    SELECT approval_status
    INTO invoice_status
    FROM Invoice
    WHERE invoice_num = new_invoice;
    
    IF invoice_status <> 'PENDING' OR invoice_status IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invoice must be pending to add invoice line items';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Product
    WHERE vendor_pnum = new_product_num;

    -- verifies product number is valid
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'product number not found';
        
	-- verifies quantity is valid
	ELSEIF new_quantity <= 0 OR new_quantity IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invoice quantity must be strictly positive';	
	END IF;
    
    SELECT vendor_num
    INTO invoice_vendor
    FROM Invoice
    WHERE invoice_num = new_invoice;
    
    SELECT vendor_num
    INTO product_vendor
    FROM Product
    WHERE vendor_pnum = new_product_num;
    
    -- checks that invoice's vendor matches product's vendor
    IF invoice_vendor IS NULL OR TRIM(invoice_vendor) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invoice vendor is ilegal';
	ELSEIF product_vendor IS NULL OR TRIM(product_vendor) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product vendor is ilegal';
	ELSEIF product_vendor <> invoice_vendor THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'product and invoice vendors do not match';
    END IF;
    
    INSERT INTO InvoiceLine(
		invoice_num,
        vendor_pnum,
        quantity
    ) VALUES(
		new_invoice,
        new_product_num,
        new_quantity
    );
    
    SELECT internal_num, price, conversion_factor
    INTO new_internal_num, new_product_price, v_factor
    FROM Product
    WHERE vendor_pnum = new_product_num;
    
    -- verifies data from product is valid
    IF new_internal_num IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'item internal number not found';
	ELSEIF new_product_price <= 0 OR new_product_price IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'price must be stricly positive';
	ELSEIF v_factor <= 0 OR v_factor IS NULL THEN
			SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'conversion factor must be stricly positive';	
	END IF;
    
    SET new_product_price = new_product_price / v_factor;
	
    INSERT INTO InventoryTransaction(
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
    ) VALUES(
		new_internal_num,
        'RECEIVE',
        new_quantity,
        CURRENT_TIMESTAMP,
        NULL,
        'PENDING',
        new_invoice,
        new_product_num,
        new_product_price,
        NULL
    );
    
END $$

DELIMITER ;