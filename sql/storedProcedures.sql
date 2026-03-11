DROP PROCEDURE IF EXISTS enter_waste;
DROP PROCEDURE IF EXISTS use_product;
DROP PROCEDURE IF EXISTS adjust_inventory;
DROP PROCEDURE IF EXISTS receive_product;
DELIMITER $$

CREATE PROCEDURE enter_waste(
    IN trans_num VARCHAR(64), 
    IN item VARCHAR(20), 
    IN quantity DECIMAL(10,3), 
    IN trans_date DATETIME,
    IN manager VARCHAR(20), 
    IN reason VARCHAR(64)
)
BEGIN
    INSERT INTO InventoryTransaction (
        transaction_num,
        internal_num,
        transaction_type,
        quantity,
        transaction_date,
        manager,
        invoice_num,
        reason
    )
    VALUES (
        trans_num,
        item,
        'WASTE',
        quantity,
        trans_date,
        manager,
        NULL,
        reason
    );
END $$


CREATE PROCEDURE use_product(
    IN trans_num VARCHAR(64), 
    IN item VARCHAR(20), 
    IN quantity DECIMAL(10,3), 
    IN trans_date DATETIME,
    IN manager VARCHAR(20) 
)
BEGIN
    INSERT INTO InventoryTransaction (
        transaction_num,
        internal_num,
        transaction_type,
        quantity,
        transaction_date,
        manager,
        invoice_num,
        reason
    )
    VALUES (
        trans_num,
        item,
        'USE',
        quantity,
        trans_date,
        manager,
        NULL,
        NULL
    );
END $$

CREATE PROCEDURE adjust_inventory(
    IN trans_num VARCHAR(64), 
    IN item VARCHAR(20), 
    IN quantity DECIMAL(10,3), 
    IN trans_date DATETIME,
    IN manager VARCHAR(20),
    IN reason VARCHAR(64)
)
BEGIN
    INSERT INTO InventoryTransaction (
        transaction_num,
        internal_num,
        transaction_type,
        quantity,
        transaction_date,
        manager,
        invoice_num,
        reason
    )
    VALUES (
        trans_num,
        item,
        'ADJUST',
        quantity,
        trans_date,
        manager,
        NULL,
        reason
    );
END $$

CREATE PROCEDURE receive_product(
    IN trans_num VARCHAR(64), 
    IN item VARCHAR(20), 
    IN quantity DECIMAL(10,3), 
    IN trans_date DATETIME,
    IN manager VARCHAR(20),
    IN invoice VARCHAR(20)
)
BEGIN
    INSERT INTO InventoryTransaction (
        transaction_num,
        internal_num,
        transaction_type,
        quantity,
        transaction_date,
        manager,
        invoice_num,
        reason
    )
    VALUES (
        trans_num,
        item,
        'RECEIVE',
        quantity,
        trans_date,
        manager,
        invoice,
        NULL
    );
END $$

