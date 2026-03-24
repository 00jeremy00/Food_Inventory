
USE FOOD;

CREATE TABLE IF NOT EXISTS Category(
	category_name VARCHAR(64) PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS Item(
	internal_num VARCHAR(20) PRIMARY KEY,
    internal_name VARCHAR(64) NOT NULL,
    category VARCHAR(64) NOT NULL,
    internal_unit VARCHAR(20) NOT NULL,
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
	product_num INT AUTO_INCREMENT PRIMARY KEY,
    vendor_pnum VARCHAR(64) NOT NULL,
    vendor_pname VARCHAR(255) NOT NULL,
    internal_num VARCHAR(20) NOT NULL,
    purchase_unit VARCHAR(20) NOT NULL,
    vendor_num VARCHAR(6) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    conversion_factor DECIMAL(10,3) NOT NULL,
    FOREIGN KEY (vendor_num) REFERENCES Vendor(vendor_num),
    FOREIGN KEY (internal_num) REFERENCES Item(internal_num)
);

CREATE TABLE IF NOT EXISTS Employee(
	employee_num VARCHAR(20) PRIMARY KEY,
    employee_name VARCHAR(64) NOT NULL,
    is_manager BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS Invoice(
	invoice_id INT AUTO_INCREMENT PRIMARY KEY,
	invoice_num VARCHAR(20) NOT NULL,
    invoice_date DATE NOT NULL,
    vendor_num VARCHAR(6) NOT NULL,
    approval_status ENUM('APPROVED', 'PENDING', 'DENIED') DEFAULT 'PENDING' NOT NULL,
    approved_by VARCHAR(20),
    FOREIGN KEY (vendor_num) REFERENCES Vendor(vendor_num),
    FOREIGN KEY (approved_by) REFERENCES Employee(employee_num)
);

CREATE TABLE IF NOT EXISTS InvoiceLine(
	invoice_id INT NOT NULL,
    product_num INT NOT NULL,
    quantity DECIMAL(10,3) NOT NULL,
    PRIMARY KEY (invoice_id, product_num),
    FOREIGN KEY (invoice_id) REFERENCES Invoice (invoice_id),
    FOREIGN KEY (product_num) REFERENCES Product (product_num)
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
    approved_by VARCHAR(20),
    created_by VARCHAR(20),
    approval_status ENUM('APPROVED', 'PENDING', 'DENIED') DEFAULT 'PENDING' NOT NULL,
    invoice_id INT,
    product_num INT,
    price_per_unit DECIMAL(10,3),
    reason VARCHAR(64),
    FOREIGN KEY (product_num) REFERENCES Product(product_num),
	FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id),
    FOREIGN KEY (internal_num) REFERENCES Item(internal_num),
    FOREIGN KEY (approved_by) REFERENCES Employee(employee_num),
    CONSTRAINT valid_type CHECK (transaction_type IN ('RECEIVE', 'USE', 'WASTE', 'ADJUST'))
);

CREATE TABLE IF NOT EXISTS InventorySnapshotRecord(
	snapshot_id INT AUTO_INCREMENT PRIMARY KEY,
	snapshot_time DATETIME NOT NULL,
    previous_snapshot INT NULL,
    snapshot_status ENUM('PENDING', 'COMPLETED') DEFAULT 'PENDING' NOT NULL,
    manager_num VARCHAR(20) NOT NULL,
    notes VARCHAR(255),
    FOREIGN KEY (manager_num) REFERENCES Employee(employee_num)
);

CREATE TABLE IF NOT EXISTS InventorySnapshot(
	snapshot_id INT NOT NULL,
    product_num INT NOT NULL,
    expected_quantity DECIMAL(10,3) NOT NULL,
    counted_quantity DECIMAL(10,3) NOT NULL,
    PRIMARY KEY(snapshot_id, product_num),
    FOREIGN KEY(product_num) REFERENCES Product(product_num),
    FOREIGN KEY(snapshot_id) REFERENCES InventorySnapshotRecord(snapshot_id)
);

CREATE TABLE IF NOT EXISTS ItemVariance(
	snapshot_id INT NOT NULL,
    internal_num VARCHAR(20) NOT NULL,
    expected_quantity DECIMAL(10,3) NOT NULL,
    counted_quantity DECIMAL(10,3) NOT NULL,
    PRIMARY KEY(snapshot_id, internal_num),
    FOREIGN KEY(snapshot_id) REFERENCES InventorySnapshotRecord(snapshot_id),
	FOREIGN KEY(internal_num) REFERENCES Item(internal_num)
);

SHOW TABLES;
