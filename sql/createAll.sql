
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
    FOREIGN KEY (internal_num) REFERENCES Item(internal_num),
    CONSTRAINT price_not_positive CHECK (price > 0)
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
    FOREIGN KEY (approved_by) REFERENCES Employee(employee_num),
    CONSTRAINT valid_status CHECK (approval_status IN ('APPROVED', 'PENDING', 'DENIED'))
);

CREATE TABLE IF NOT EXISTS InvoiceLine(
	invoice_id INT NOT NULL,
    product_num INT NOT NULL,
    quantity DECIMAL(10,3) NOT NULL,
    line_price DECIMAL(10,3) NOT NULL,
    PRIMARY KEY (invoice_id, product_num),
    FOREIGN KEY (invoice_id) REFERENCES Invoice (invoice_id),
    FOREIGN KEY (product_num) REFERENCES Product (product_num),
    CONSTRAINT line_price_positive CHECK (line_price > 0)
);

CREATE TABLE IF NOT EXISTS ProductInventory(
	product_num INT PRIMARY KEY,
    quantity DECIMAL(10,3) DEFAULT 0.0 NOT NULL,
    FOREIGN KEY (product_num) REFERENCES Product(product_num),
    CONSTRAINT non_negative_inventory CHECK (quantity >= 0)
);

CREATE TABLE IF NOT EXISTS Recipe(
	recipe_num INT AUTO_INCREMENT PRIMARY KEY,
    recipe_name VARCHAR(64) NOT NULL,
    is_active BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS Ingredient(
	recipe_num INT NOT NULL,
    internal_num VARCHAR(20) NOT NULL,
    quantity DECIMAL(10,3) NOT NULL,
    CONSTRAINT quantity_positive CHECK (quantity > 0),
    FOREIGN KEY (recipe_num) REFERENCES Recipe(recipe_num),
	FOREIGN KEY (internal_num) REFERENCES Item(internal_num),
    PRIMARY KEY(recipe_num, internal_num)
    );

CREATE TABLE IF NOT EXISTS PrepPlan(
	plan_num INT AUTO_INCREMENT PRIMARY KEY,
    recipe_num INT NOT NULL,
    plan_date DATE NOT NULL,
    recipe_quantity DECIMAL(10,3) NOT NULL DEFAULT 1,
    FOREIGN KEY (recipe_num) REFERENCES Recipe(recipe_num)
);

CREATE TABLE IF NOT EXISTS InventoryTransaction(
	transaction_num INT AUTO_INCREMENT PRIMARY KEY,
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
    FOREIGN KEY(plan_num) REFERENCES PrepPlan(plan_num),
    FOREIGN KEY (product_num) REFERENCES Product(product_num),
	FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id),
    FOREIGN KEY (approved_by) REFERENCES Employee(employee_num),
    FOREIGN KEY (created_by) REFERENCES Employee(employee_num),
    CONSTRAINT valid_transaction_type CHECK (transaction_type IN ('RECEIVE', 'USE', 'WASTE', 'ADJUST')),
    CONSTRAINT valid_trans_status CHECK (approval_status IN ('APPROVED', 'PENDING', 'DENIED')),
    CONSTRAINT trans_quantity_positive CHECK (quantity > 0),
    CONSTRAINT trans_price_positive CHECK (price_per_unit > 0 OR price_per_unit IS NULL)
);

CREATE TABLE IF NOT EXISTS InventorySnapshotRecord(
	snapshot_id INT AUTO_INCREMENT PRIMARY KEY,
	snapshot_time DATETIME NOT NULL,
    previous_snapshot INT NULL,
    snapshot_status ENUM('PENDING', 'COMPLETED') DEFAULT 'PENDING' NOT NULL,
    recorded_by VARCHAR(20) NOT NULL,
    notes VARCHAR(255),
    FOREIGN KEY (recorded_by) REFERENCES Employee(employee_num),
    CONSTRAINT valid_snap_status CHECK (snapshot_status IN ('PENDING', 'COMPLETED'))
);

CREATE TABLE IF NOT EXISTS InventorySnapshot(
	snapshot_id INT NOT NULL,
    product_num INT NOT NULL,
    expected_quantity DECIMAL(10,3) NOT NULL,
    counted_quantity DECIMAL(10,3) NOT NULL,
    PRIMARY KEY(snapshot_id, product_num),
    FOREIGN KEY(product_num) REFERENCES Product(product_num),
    FOREIGN KEY(snapshot_id) REFERENCES InventorySnapshotRecord(snapshot_id),
    CONSTRAINT expected_product_positive CHECK (expected_quantity >= 0),
    CONSTRAINT counted_product_positive CHECK (counted_quantity >= 0)
);


SHOW TABLES;