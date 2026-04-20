USE FOOD;
DROP PROCEDURE IF EXISTS addItem;
DROP PROCEDURE IF EXISTS addProduct;
DROP PROCEDURE IF EXISTS addVendor;
DROP PROCEDURE IF EXISTS addEmployee;

DELIMITER $$

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

DELIMITER ;
SHOW ERRORS;