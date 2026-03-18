
USE FOOD;

CREATE TABLE IF NOT EXISTS Category(
	category_name VARCHAR(64) PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS Item(
	internal_num VARCHAR(20) PRIMARY KEY,
    internal_name VARCHAR(64) NOT NULL,
    category VARCHAR(64) NOT NULL,
    internal_unit VARCHAR(20) NOT NULL,
    average_price DECIMAL(10,3),
    FOREIGN KEY (category) REFERENCES Category(category_name)
);

CREATE TABLE IF NOT EXISTS Vendor(
	vendor_num VARCHAR(6) PRIMARY KEY,
    vendor_name VARCHAR(64) NOT NULL,
    phone_number VARCHAR(20),
    email VARCHAR(64),
    website VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS Product(
	vendor_pnum VARCHAR(64) PRIMARY KEY,
    vendor_pname VARCHAR(255) NOT NULL,
    internal_num VARCHAR(20) NOT NULL,
    purchase_unit VARCHAR(20) NOT NULL,
    vendor_num VARCHAR(6) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    conversion_factor DECIMAL(10,3) NOT NULL,
    FOREIGN KEY (vendor_num) REFERENCES Vendor(vendor_num),
    FOREIGN KEY (internal_num) REFERENCES Item(internal_num)
);

CREATE TABLE IF NOT EXISTS Manager(
	manager_num VARCHAR(20) PRIMARY KEY,
    manager_name VARCHAR(64) NOT NULL
);

CREATE TABLE IF NOT EXISTS Invoice(
	invoice_num VARCHAR(20) PRIMARY KEY,
    invoice_date DATE NOT NULL,
    vendor_num VARCHAR(6) NOT NULL,
    approval_status ENUM('APPROVED', 'PENDING', 'DENIED') DEFAULT 'PENDING' NOT NULL,
    approved_by VARCHAR(20),
    FOREIGN KEY (vendor_num) REFERENCES Vendor(vendor_num),
    FOREIGN KEY (approved_by) REFERENCES Manager(manager_num)
);

CREATE TABLE IF NOT EXISTS InvoiceLine(
	invoice_num VARCHAR(20) NOT NULL,
    vendor_pnum VARCHAR(64) NOT NULL,
    quantity DECIMAL(10,3) NOT NULL,
    PRIMARY KEY (invoice_num, vendor_pnum),
    FOREIGN KEY (invoice_num) REFERENCES Invoice (invoice_num),
    FOREIGN KEY (vendor_pnum) REFERENCES Product (vendor_pnum)
);

CREATE TABLE IF NOT EXISTS Inventory(
	internal_num VARCHAR(20) PRIMARY KEY,
    quantity DECIMAL(10,3) DEFAULT 0.0 NOT NULL,
    FOREIGN KEY (internal_num) REFERENCES Item(internal_num)
);

CREATE TABLE IF NOT EXISTS InventoryTransaction(
	transaction_num INT AUTO_INCREMENT PRIMARY KEY,
    internal_num VARCHAR(20) NOT NULL,
	transaction_type ENUM('RECEIVE', 'USE', 'WASTE', 'ADJUST') NOT NULL,
    quantity DECIMAL(10,3) NOT NULL,
    transaction_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    manager_num VARCHAR(20),
    approval_status ENUM('APPROVED', 'PENDING', 'DENIED') DEFAULT 'PENDING' NOT NULL,
    invoice_num VARCHAR(20),
    vendor_pnum VARCHAR(64),
    price_per_unit DECIMAL(10,3) NOT NULL,
    reason VARCHAR(64),
    FOREIGN KEY (vendor_pnum) REFERENCES Product(vendor_pnum),
	FOREIGN KEY (invoice_num) REFERENCES Invoice(invoice_num),
    FOREIGN KEY (internal_num) REFERENCES Item(internal_num),
    FOREIGN KEY (manager_num) REFERENCES Manager(manager_num),
    CONSTRAINT valid_type CHECK (transaction_type IN ('RECEIVE', 'USE', 'WASTE', 'ADJUST'))
);
SHOW TABLES;
