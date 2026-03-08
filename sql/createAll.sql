CREATE DATABASE IF NOT EXISTS FOOD;
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
	vendor_num VARCHAR(20) PRIMARY KEY,
    vendor_name VARCHAR(64) NOT NULL,
    phone_number VARCHAR(20),
    email VARCHAR(64),
    website VARCHAR(64)
);

CREATE TABLE IF NOT EXISTS Product(
	vendor_pnum VARCHAR(64) PRIMARY KEY,
    internal_num VARCHAR(20) NOT NULL,
    purchase_unit VARCHAR(20) NOT NULL,
    vendor_num VARCHAR(20) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (vendor_num) REFERENCES Vendor(vendor_num),
    FOREIGN KEY (internal_num) REFERENCES Item(internal_num)
);