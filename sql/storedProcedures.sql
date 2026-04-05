DROP PROCEDURE IF EXISTS resolveInvoice;
DROP PROCEDURE IF EXISTS resolveInventoryTransaction;
DROP PROCEDURE IF EXISTS createUseTransaction;
DROP PROCEDURE IF EXISTS createAdjustTransaction;
DROP PROCEDURE IF EXISTS createWasteTransaction;
DROP PROCEDURE IF EXISTS addItem;
DROP PROCEDURE IF EXISTS addProduct;
DROP PROCEDURE IF EXISTS addVendor;
DROP PROCEDURE IF EXISTS addEmployee;
DROP PROCEDURE IF EXISTS addInvoice;
DROP PROCEDURE IF EXISTS addInvoiceLine;
DROP PROCEDURE IF EXISTS addRecipe;
DROP PROCEDURE IF EXISTS addIngredient;
DROP PROCEDURE IF EXISTS createInventorySnapshotRecord;
DROP PROCEDURE IF EXISTS createInventorySnapshot;
DROP PROCEDURE IF EXISTS completeSnapshot;
DROP PROCEDURE IF EXISTS createPrepPlan;
DROP PROCEDURE createUnplannedBatch;
DROP PROCEDURE IF EXISTS executePrepPlan;



DELIMITER $$


CREATE PROCEDURE resolveInvoice(
    IN p_invoice_id INT,		-- invoice num to resolve
    IN p_approval_status VARCHAR(20),	-- resolution to invoice
    IN p_approved_by VARCHAR(20)		-- manager num who is resolving
)
BEGIN
	DECLARE v_count INT DEFAULT 0;		
    DECLARE v_old_status VARCHAR(20);	-- previous status of invoice
    DECLARE v_transaction_num INT;		-- transaction numbers connected to invoice
    DECLARE v_transaction_quantity DECIMAL(10,3);
    DECLARE v_inventory_quantity DECIMAL(10,3);
    DECLARE v_product_num INT;
    DECLARE v_invoice_vendor VARCHAR(6);
    DECLARE v_vendor VARCHAR(6);
    DECLARE v_price DECIMAL(10,3);
    DECLARE v_factor DECIMAL(10,3);
    DECLARE done INT DEFAULT FALSE;

    DECLARE cur CURSOR FOR				-- gets transaction info for transactions of selected invoice
        SELECT transaction_num, product_num, quantity, price_per_unit
        FROM InventoryTransaction
        WHERE invoice_id = p_invoice_id
          AND transaction_type = 'RECEIVE'
          AND approval_status = 'PENDING';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

	-- Ensures invoice num is given
    SELECT COUNT(*)
    INTO v_count
    FROM Invoice
    WHERE invoice_id = p_invoice_id;
    
	IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid invoice';

	-- Ensures valid approval state is being set
    ELSEIF p_approval_status NOT IN ('APPROVED','DENIED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Updated invoice must be APPROVED or DENIED';
    END IF;


	-- Ensures valid manager number is given
    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = p_approved_by
		AND is_manager = TRUE;
	
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Valid manager credentials are necessary to accept invoice';
    END IF;

    START TRANSACTION;

    /* lock the invoice row */
    SELECT approval_status
    INTO v_old_status
    FROM Invoice
    WHERE invoice_id = p_invoice_id
    FOR UPDATE;
    
	-- Ensures the invoice is in valid pending state to update
    IF v_old_status <> 'PENDING' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No pending invoice found';
    END IF;

	-- validates vendor associated with invoice
	SELECT vendor_num
    INTO v_invoice_vendor
    FROM Invoice
    WHERE invoice_id = p_invoice_id;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Vendor
    WHERE vendor_num = v_invoice_vendor;
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid vendor associated with invoice';
    END IF;

    OPEN cur;

    read_loop: LOOP
        FETCH cur 
        INTO v_transaction_num, v_product_num, v_transaction_quantity, v_price;
        IF done THEN
            LEAVE read_loop;
        END IF;

		-- invoice aproval must update inventory
        IF p_approval_status = 'APPROVED' THEN
            INSERT INTO ProductInventory (product_num, quantity)
            VALUES (v_product_num, 0)
            ON DUPLICATE KEY UPDATE product_num = v_product_num;
            
            IF v_product_num IS NULL THEN
				SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'transaction does not have product number';
            END IF;
            
            SELECT  COUNT(*)
            INTO v_count
            FROM Product
            WHERE product_num = v_product_num;
            
            -- checks to make sure product has valid product_num
            IF v_count = 0 THEN
				SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'product number invalid';
			END IF;
            
            SELECT conversion_factor
            INTO v_factor
            FROM Product
            WHERE product_num = v_product_num;
            
            IF v_factor IS NULL OR v_factor <= 0 THEN
				SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'conversion factor is invalid';
			END IF;
            
            SELECT vendor_num
            INTO v_vendor
            FROM Product
            WHERE product_num = v_product_num;
            
            IF v_vendor <> v_invoice_vendor THEN
				SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Invoice\'s vendor does not sell the transaction\'s product';
			END IF;
            
            -- validates price and conversion factor
            IF v_price IS NULL OR v_price <= 0 THEN
				SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Invalid transaction product price';
			END IF;
            
            -- update product price
            UPDATE Product
            SET price = v_price * v_factor
            WHERE product_num = v_product_num;

            SELECT quantity
            INTO v_inventory_quantity
            FROM ProductInventory
            WHERE product_num = v_product_num
            FOR UPDATE;

            UPDATE ProductInventory
            SET quantity = v_inventory_quantity + v_transaction_quantity
            WHERE product_num = v_product_num;
            
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
    WHERE invoice_id = p_invoice_id;

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
    DECLARE v_transaction_product INT;
    DECLARE v_creator VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

	-- Ensures that resolution status is aprroved or denied
    IF p_new_status NOT IN ('APPROVED', 'DENIED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory transaction must be resolved as APPROVED or DENIED';
	
    -- ensures that valid transaction number was given
	ELSEIF p_transaction_num IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Transaction Number chosen for resolution';  
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM InventoryTransaction
    WHERE transaction_num = p_transaction_num;

	-- makes sure transactionn number matches transaction
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction not found';
	-- ensures that approval is valid and employee num refers to a manager
	ELSEIF p_approved_by IS NULL OR TRIM(p_approved_by) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid approval credentials';
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Employee 
    WHERE employee_num = p_approved_by
    AND is_manager = TRUE;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No manager found matching approver credentials';
	END IF;

    START TRANSACTION;
    
    SELECT approval_status, transaction_type, product_num, quantity, created_by
    INTO v_old_status, v_transaction_type, v_transaction_product, v_transaction_quantity, v_creator
    FROM InventoryTransaction
    WHERE transaction_num = p_transaction_num
    FOR UPDATE;

	SELECT COUNT(*) 
    INTO v_count
    FROM Employee
    WHERE employee_num = v_creator;
    
    -- enures tranaction has a valid creator
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction does not have a valid creator';
	END IF;

	-- enure transaction has not already been resolved
    IF v_old_status <> 'PENDING' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Resolved transactions cannot be updated';
    END IF;

	SELECT COUNT(*) 
    INTO v_count
    FROM Product
    WHERE product_num = v_transaction_product;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Transaction product number';
    END IF;

	-- verfies that transaction type is valid
    IF v_transaction_type = 'RECEIVE' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RECEIVE transactions must be resolved through invoice approval';
	ELSEIF v_transaction_type NOT IN ('WASTE', 'USE', 'ADJUST') THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid transaction type';
    END IF;
    
    IF v_transaction_quantity < 0 AND v_transaction_type <> 'ADJUST' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction quantity can only be negative for ADJUST transactions';	
	END IF;
    
    IF p_new_status = 'APPROVED' THEN
		-- ensures that inventory record exists for product
        INSERT INTO ProductInventory (product_num, quantity)
        VALUES (v_transaction_product, 0)
		ON DUPLICATE KEY UPDATE quantity = ProductInventory.quantity;
        
        SELECT quantity
        INTO v_inventory_quantity
        FROM ProductInventory
        WHERE product_num = v_transaction_product
        FOR UPDATE;

		-- calculates new inventory number after change
        IF v_transaction_type IN ('WASTE', 'USE') THEN
            SET v_inventory_quantity = v_inventory_quantity - v_transaction_quantity;

        ELSEIF v_transaction_type = 'ADJUST' THEN
            SET v_inventory_quantity = v_inventory_quantity + v_transaction_quantity;
        END IF;

		-- ensure new inventory quantity is not negative
        IF v_inventory_quantity < 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Transaction cannot make inventory negative';
        END IF;

        UPDATE ProductInventory
        SET quantity = v_inventory_quantity
        WHERE product_num = v_transaction_product;
    END IF;

	UPDATE InventoryTransaction
	SET approval_status = p_new_status,
		approved_by = p_approved_by
	WHERE transaction_num = p_transaction_num;

    COMMIT;
END$$

CREATE PROCEDURE createUseTransaction( 
    IN use_product INT, 
    IN use_quantity DECIMAL(10,3), 
    IN creator VARCHAR(20)
)
BEGIN
    DECLARE v_count INT;
    DECLARE v_price DECIMAL(10,3);
    DECLARE v_conversion DECIMAL(10,3);
	
    IF creator IS NULL OR TRIM(creator) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory Tranactions must have creator';
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = creator;
    
    -- ensures quantity is not 0 or negative for use
    IF use_quantity <= 0 OR use_quantity IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity for use must be strictly positive';
    -- if manager number is given, ensures it is valid
    ELSEIF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee number is invalid';
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Product 
    WHERE product_num = use_product;
    
    -- ensures transaction is occurring on an item in the database
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product number does not match valid product';
    END IF;

	SELECT price, conversion_factor
	INTO v_price, v_conversion
	FROM Product
	WHERE product_num = use_product;
        
	-- ensures that conversion factor is positive
	IF v_conversion <= 0 OR v_conversion IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Invalid conversion factor';
	-- ensures that product price is positive
	ELSEIF v_price <= 0 OR v_price IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Invalid product price';
	END IF;
        
	SET v_price = v_price / v_conversion;

    INSERT INTO InventoryTransaction (
        transaction_type,
        quantity,
        transaction_date,
        created_by,
        approval_status,
        price_per_unit,
        product_num       
    )
    VALUES (
        'USE',
        use_quantity,
        CURRENT_TIMESTAMP,
        creator,
        'PENDING',
        v_price,
        use_product
    );
END $$

CREATE PROCEDURE createAdjustTransaction( 
    IN adjust_product INT, 
    IN trans_quantity DECIMAL(10,3), 
    IN creator VARCHAR(20),
    IN adjust_reason VARCHAR(64)
)
BEGIN
    DECLARE v_count INT;
    DECLARE v_price DECIMAL(10,3);
    DECLARE v_conversion DECIMAL(10,3);

	-- Verifies that product number is not NULL
	IF adjust_product IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product number needed for adjustment';
	END IF;
    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = creator;
    
    -- ensures quantity is not 0
    IF trans_quantity = 0 OR trans_quantity IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Adjustment quantity cannot be zero';
    -- ensures manager number is valid
    ELSEIF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee number is invalid';
    -- ensures reason is given
    ELSEIF adjust_reason IS NULL OR TRIM(adjust_reason) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Adjustments to inventory must have a reason';    
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM Product
    WHERE product_num = adjust_product;
    
    -- ensures transaction is occurring on valid product
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid product number';        
    END IF;
    
        
        
	SELECT price, conversion_factor
	INTO v_price, v_conversion
	FROM Product
	WHERE product_num = adjust_product;
        
	-- ensures conversion factor and product price are positive 
	IF v_conversion <= 0 OR v_conversion IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Invalid conversion factor';
	ELSEIF v_price <= 0 OR v_price IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Invalid product price';
	END IF;
        
	SET v_price = v_price / v_conversion;
    
    INSERT INTO InventoryTransaction (
        transaction_type,
        quantity,
        transaction_date,
        created_by,
        approval_status,
        invoice_id,
        product_num,
        price_per_unit,
        reason
    )
    VALUES (
        'ADJUST',
        trans_quantity,
        CURRENT_TIMESTAMP,
        creator,
        'PENDING',
        NULL,
        adjust_product,
        v_price,
        TRIM(adjust_reason)
    );
END $$

CREATE PROCEDURE createWasteTransaction(
    IN waste_product INT,
    IN trans_quantity DECIMAL(10,3),
    IN creator VARCHAR(20),
    IN waste_reason VARCHAR(64)
)
BEGIN
    DECLARE v_count INT;
    DECLARE v_price DECIMAL(10,3);
    DECLARE v_conversion DECIMAL(10,3);
    
    -- verifies product being wasted is not null
    IF waste_product IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction requires valid product';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Product
    WHERE product_num = waste_product;
    
    -- verifies transaction quantity is strictly positive and not NULL
    IF trans_quantity <= 0 OR trans_quantity IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Waste entry must have quantity greater than 0';
    
    -- verifies procut number refers to a valid product
    ELSEIF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid product number for waste transaction';
    ELSEIF waste_reason IS NULL OR TRIM(waste_reason) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Waste entry must have a reason';
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = creator;
    
    -- enure creator is a valid employee
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee number is invalid';
    END IF;
    
        
	SELECT price, conversion_factor
	INTO v_price, v_conversion
	FROM Product
	WHERE product_num = waste_product;
        
	-- checks to make sure price is strictly positive and not NULL
	IF v_price <= 0 OR v_price IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Invalid product price';
	-- checks to make sure conversion factor is positive
	ELSEIF v_conversion <= 0 OR v_conversion IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Invalid conversion factor';    
	END IF;
        
	SET v_price = v_price / v_conversion;
    
    INSERT INTO InventoryTransaction(
        transaction_type,
        quantity,
        transaction_date,
        created_by,
        approval_status,
        invoice_id,
        reason,
        product_num,
        price_per_unit
    )
    VALUES (
        'WASTE',
        trans_quantity,
        CURRENT_TIMESTAMP,
        creator,
        'PENDING',
        NULL,
        TRIM(waste_reason),
        waste_product,
        v_price
    );
END $$

CREATE PROCEDURE addItem(
	IN new_id VARCHAR(20),
    IN new_name VARCHAR(64),
    IN new_category VARCHAR(64),
    IN new_unit VARCHAR(20)
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
        SET MESSAGE_TEXT = 'internal item  number already taken';
        
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
	END IF;
    
    INSERT INTO Item(
		internal_num,
        internal_name,
        category,
        internal_unit
	)
	VALUES (
		new_id,
        new_name,
        new_category,
        new_unit
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
    FROM Vendor
    WHERE vendor_num = new_vendor;

    -- verifie that vendor is valid
    IF new_vendor IS NULL OR TRIM(new_vendor) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Vendor number is required';
    ELSEIF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid vendor number';    
    END IF;
    
    -- verifies product number is valid and not taken
    IF new_product IS NULL OR TRIM(new_product) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Vendor product number is required'; 
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Product
    WHERE vendor_pnum = new_product
      AND vendor_num = new_vendor;

    -- enures that producut_num, vendor is a unique combonation 
    IF v_count <> 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Vendor product number already exists for this vendor';
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
        SET MESSAGE_TEXT = 'conversion factor must be strictly positive';
    
    ELSEIF new_price IS NULL OR new_price <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'strictly positive price is required for new product';    
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

CREATE PROCEDURE addEmployee(
	IN new_employee_num VARCHAR(20),
    IN new_name VARCHAR(64),
    IN manager_status BOOL
)
BEGIN 
	DECLARE v_count INT;
    
    SELECT COUNT(*)
    INTO v_count 
    FROM Employee
    WHERE employee_num = new_employee_num;
    
    IF new_employee_num IS NULL OR TRIM(new_employee_num) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'employee number required';
	ELSEIF v_count <> 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'employee number already taken';
	ELSEIF new_name IS NULL OR TRIM(new_name) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'employee name is required';
	ELSEIF manager_status IS NULL THEN
    	SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid manager status';
	END IF;
    
    INSERT INTO Employee(
		employee_num,
        employee_name,
        is_manager
    )
    VALUES(
		new_employee_num,
        new_name,
        manager_status
    );
END $$

CREATE PROCEDURE addInvoice(
	IN new_invoice VARCHAR(20),
	IN new_date DATE,
    IN new_vendor VARCHAR(6)
)
BEGIN
	DECLARE v_count INT;
    
    IF new_vendor IS NULL AND TRIM(new_vendor) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '';
    END IF;
    
	SELECT COUNT(*)
    INTO v_count
    FROM Vendor
    WHERE vendor_num = new_vendor;
    
    -- verifies that the vendor is valid
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invalid vendor number';	
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Invoice
    WHERE invoice_num = new_invoice
    AND vendor_num = new_vendor;
    
    -- verifies invoice number is valid
    IF new_invoice IS NULL OR TRIM(new_invoice) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invoice number needed for invoice';
        
	-- verifies that an invoice with the same invoice num and vendor does not exist
	ELSEIF v_count <> 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invoice number in use';
    END IF;
    
    -- verifies date 
    IF new_date IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invalid date';	
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
    IN new_invoice INT,
    IN new_product_num INT,
    IN new_quantity DECIMAL(10,3),
    IN creator VARCHAR(20),
    IN new_line_price DECIMAL(10,3)
)
BEGIN
    DECLARE v_count INT;
    DECLARE new_product_price DECIMAL(10,3);
    DECLARE invoice_status VARCHAR(20);
    DECLARE product_vendor VARCHAR(6);
    DECLARE invoice_vendor VARCHAR(6);
    DECLARE v_factor DECIMAL(10,3);
    DECLARE v_internal_quantity DECIMAL(10,3);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- ensure invoice id is given
    IF new_invoice IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No invoice id given';
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Invoice
    WHERE invoice_id = new_invoice;
    
    -- verifies invoice exists
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invoice not found';
    END IF;
    
    SELECT approval_status, vendor_num
    INTO invoice_status, invoice_vendor
    FROM Invoice
    WHERE invoice_id = new_invoice;
    
    -- ensures invoice is still pending
    IF invoice_status IS NULL OR invoice_status <> 'PENDING' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invoice must be pending to add invoice line items';
    END IF;
    
    -- validate price of invoice line
    IF new_line_price IS NULL OR new_line_price <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Line price for invoice line invalid';
    END IF;
    
    -- ensures creator is provided
    IF creator IS NULL OR TRIM(creator) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory transaction requires creator';
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = creator;
    
    -- verifies that creator is a valid employee
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid employee number for creator';
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Product
    WHERE product_num = new_product_num;

    -- verifies product number is valid
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product number not found';
    END IF;

    -- verifies quantity is strictly positive
    IF new_quantity IS NULL OR new_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invoice quantity must be strictly positive';
    END IF;
    
    SELECT vendor_num, conversion_factor
    INTO product_vendor, v_factor
    FROM Product
    WHERE product_num = new_product_num;
    
    -- checks that invoice's vendor matches product's vendor
    IF invoice_vendor IS NULL OR TRIM(invoice_vendor) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invoice does not list vendor';
    ELSEIF product_vendor IS NULL OR TRIM(product_vendor) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product vendor is invalid';
    ELSEIF product_vendor <> invoice_vendor THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product and invoice vendors do not match';
    END IF;
    
    -- verifies conversion factor is valid
    IF v_factor IS NULL OR v_factor <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Conversion factor must be strictly positive';
    END IF;

    -- prevents duplicate invoice line entries for same product
    SELECT COUNT(*)
    INTO v_count
    FROM InvoiceLine
    WHERE invoice_id = new_invoice
      AND product_num = new_product_num;

    IF v_count <> 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product already exists on this invoice';
    END IF;

    -- converts ordered quantity into internal units
    SET v_internal_quantity = new_quantity * v_factor;

    -- calculates price per internal unit
    SET new_product_price = new_line_price / v_internal_quantity;

    START TRANSACTION;
    
    -- inserts invoice line record
    INSERT INTO InvoiceLine(
        invoice_id,
        product_num,
        quantity,
        line_price
    ) VALUES(
        new_invoice,
        new_product_num,
        new_quantity,
        new_line_price
    );
    
    -- creates corresponding RECEIVE transaction (pending approval)
    INSERT INTO InventoryTransaction(
        transaction_type,
        quantity,
        transaction_date,
        approved_by,
        created_by,
        approval_status,
        invoice_id,
        product_num,
        price_per_unit,
        reason
    ) VALUES(
        'RECEIVE',
        v_internal_quantity,
        CURRENT_TIMESTAMP,
        NULL,
        creator,
        'PENDING',
        new_invoice,
        new_product_num,
        new_product_price,
        NULL
    );

    COMMIT;
END $$

CREATE PROCEDURE addRecipe(
	IN new_recipe_name VARCHAR(64),
    IN new_active BOOLEAN,
    in shelf_life_hour DECIMAL(10,3)
)
BEGIN
	-- validates recipe name
	IF new_recipe_name IS NULL OR TRIM(new_recipe_name) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Recipe must have name';
        
	-- ensures active status is not NULL
	ELSEIF new_active IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid active status';
	ELSEIF shelf_life_hour IS NULL OR shelf_life_hour <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'shelf life must be strictly positive';
	END IF;
    
    
    INSERT INTO Recipe(
		recipe_name,
        is_active,
        shelflife
	) VALUES(
       TRIM(new_recipe_name),
       new_active,
       shelf_life_hour
	);
    
END $$

CREATE PROCEDURE addIngredient(
	IN new_item VARCHAR(20),
    IN ingredient_recipe INT,
    IN new_quantity DECIMAL(10,3)
)
BEGIN
	DECLARE v_count INT;
    
    -- verifies recipe number is valid
    IF ingredient_recipe IS NULL OR ingredient_recipe < 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Recipe Number';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Recipe
    WHERE recipe_num = ingredient_recipe;
    
    -- verifies recipe number referes to a real recipe
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Recipe not found';
    
    -- verifies that item has a valid string
    ELSEIF new_item IS NULL or TRIM(new_item) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'item number invalid';
	END IF;
    
    SELECT COUNT(*) 
    INTO v_count
    FROM Item
    WHERE internal_num = new_item;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Item does not exist';
	ELSEIF new_quantity <= 0 OR new_quantity is NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ingredient quantity is invalid';
	END IF;
    
    INSERT INTO Ingredient(
		recipe_num,
		internal_num,
        quantity
    ) VALUES(
		ingredient_recipe,
		new_item,
        new_quantity
    );
    
END$$

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

CREATE PROCEDURE createInventorySnapshot(
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
    WHERE snapshot_id = inventory_snapshot;

	-- verififes that the snapshot record exists
	IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'snapshot id not found in snapshot records';
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
    
    INSERT INTO InventorySnapshot(
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
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

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

CREATE PROCEDURE createPrepPlan(
	IN new_plan_recipe INT,
    IN new_plan_date DATE,
    IN new_quantity DECIMAL(10,3),
    IN new_plan_shift VARCHAR(20),
    IN new_planner VARCHAR(20)
)
BEGIN
	DECLARE v_count INT;
    DECLARE recipe_active BOOLEAN;
    
    -- Verify that recipe is valid
    IF new_plan_recipe IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E01]: recipe is NULL';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Recipe
    WHERE recipe_num = new_plan_recipe;
    
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E02]: recipe does not exist';
	END IF;
    
    SELECT is_active 
    INTO recipe_active
    FROM Recipe
    WHERE recipe_num = new_plan_recipe;
    
    IF NOT recipe_active THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E03]: recipe is inactive';
	END IF;
    
    IF new_plan_date IS NULL OR new_plan_date < CURRENT_DATE THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E04]: plan date is invalid';
    ELSEIF new_quantity IS NULL OR new_quantity <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E05]: planned recipe quantity is invalid';
	END IF;
    
    IF new_plan_shift IS NULL OR TRIM(new_plan_shift) = '' THEN
		SET new_plan_shift = NULL;
	ELSE 
		SELECT COUNT(*)
        INTO v_count
        FROM Shift
        WHERE shift_name = new_plan_shift;
        
        IF v_count = 0 THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'createPrepPlan [E06]: Non Null shift does not exist';
		END IF;
	END IF;
    
    IF new_planner IS NULL OR TRIM(new_planner) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E07]: Invalid employee who made plan';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = new_planner;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'createPrepPlan [E08]: Employee does not exist';
	END IF;
    
    INSERT INTO PrepPlan(
		recipe_num,
		plan_date,
		planned_quantity,
		planned_shift,
		planned_by,
        plan_status
    ) VALUES(
		new_plan_recipe,
        new_plan_date,
        new_quantity,
        new_plan_shift,
        new_planner,
        'PENDING'
    );
END$$

CREATE PROCEDURE createUnplannedBatch(
	IN batch_recipe INT,
    IN recipe_quantity DECIMAL(10,3),
    IN batch_creator VARCHAR(20)
)
BEGIN
	DECLARE v_count INT;
    
    IF batch_recipe IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'createBatch [E01]: Recipe is NULL';
	END IF;

	SELECT COUNT(*)
	INTO v_count
	FROM Recipe
	WHERE recipe_num = batch_recipe;
        
	IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'createBatch [E02]: Recipe does not exist';
	
    ELSEIF recipe_quantity IS NULL or recipe_quantity <= 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'createBatch [E03]: Invalid recipe quantity';
        
	ELSEIF batch_creator IS NULL OR TRIM(batch_creator) = '' THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'createBatch [E04]: Batch creator is NULL';
	END IF;
    
	SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = batch_creator;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'createBatch [E05]: Employee not found';
	END IF;
    
    INSERT INTO Batch(
		recipe_num,
        created_on, 
        created_by,
        quantity_prepared,
        quantity_remaining,
        expires_at,
        plan_num,
        batch_status
    ) VALUES(
		batch_recipe,
        NULL,
        batch_creator,
        recipe_quantity,
        recipe_quantity,
        NULL,
        NULL,
        'PENDING'
    );
        
END$$

CREATE PROCEDURE executePrepPlan(
	IN plan_execute INT,
    IN batch_creator VARCHAR(20)
)
BEGIN 
	DECLARE v_count INT;
    DECLARE verify_recipe INT;
    DECLARE verify_quantity DECIMAL(10,3);
    DECLARE verify_date DATE;
    DECLARE verify_shift VARCHAR(20);
    DECLARE verify_status VARCHAR(20);
    DECLARE verify_start TIME;
    DECLARE verify_end TIME;
    
    IF plan_execute IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E01]: plan_num is NULL';
	END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM PrepPlan
    WHERE plan_num = plan_execute;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E02]: Plan does not exist';
	END IF;
    
    IF batch_creator IS NULL OR TRIM(batch_creator) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E03]: batch_creator is NULL';
	END IF;
    SELECT COUNT(*)
    INTO v_count
    FROM Employee
    WHERE employee_num = batch_creator;
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E04]: Employee not found';
	END IF;

    SELECT recipe_num, plan_date, quantity, shift_name, plan_status
    INTO verify_recipe, verify_date, verify_quantity, verify_shift, verify_status
    FROM PrepPlan
    WHERE plan_num = plan_execute;
    
    IF verify_recipe IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E05]: recipe_num is NULL';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Recipe
    WHERE recipe_num = verify_recipe;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E06]: Recipe not found';
	ELSEIF verify_date IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E07]: plan_date is NULL';
	ELSEIF verify_date = CURRENT_DATE THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E08]: Batch date must match plan date';
	ELSEIF verify_quantity IS NULL OR verify_quantity <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E09]: Invalid quantity';
	ELSEIF verify_shift IS NULL OR TRIM(verify_shift) = '' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E10]: Invalid Shift';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Shift
    WHERE shift_name = verify_shift;
    
    IF v_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E11]: Shift not found';
	END IF;
    
    SELECT start_time, end_time
    INTO verify_start, verify_end
    FROM Shift
    WHERE shift_name = verify_shift;
    
    IF CURRENT_TIME > verify_end OR CURRENT_TIME < verify_start THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E12]: Outiside scheduled shift time.';
	END IF;
    
    IF verify_status <> 'PENDING' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E13]: Plan must be PENDING to execute';
	END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Batch
    WHERE plan_num = plan_execute;
    
    IF v_count <> 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'executePrepPlan [E14]: Batch for plan already exists';
	END IF;
    
    INSERT INTO Batch(
		recipe_num,
        created_on, 
        created_by,
        quantity_prepared,
        quantity_remaining,
        expires_at,
        plan_num,
        batch_status
    ) VALUES(
		verify_recipe,
        NULL,
        batch_creator,
        verify_quantity,
        verify_quantity,
        NULL,
        plan_execute,
        'PENDING');
END$$


DELIMITER ;