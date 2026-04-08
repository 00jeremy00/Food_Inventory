DROP PROCEDURE IF EXISTS resolveInvoice;
DROP PROCEDURE IF EXISTS addInvoice;
DROP PROCEDURE IF EXISTS addInvoiceLine;

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

DELIMITER ;