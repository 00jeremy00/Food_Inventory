USE FOOD;
SELECT *
FROM Item;
INSERT INTO Category VALUES
('REFRIGERATED'),
('DRY FOOD'),
('FROZEN'),
("PRODUCE"),
("MEAT"),
("PAPER GOODS");

INSERT INTO Vendor VALUES
("000001", "Webstaraunt",
"717-657-8931", "support@webstaraunt.com",
"https://www.webstaurant.com"),
("000002", "Sysco",
"1(281)584-1300", "support@sysco.com",
"https://www.sysco.com/"),
("000003", "US Foods",
"1(847)720-8000", "info@usfoods.com",
"https://www.usfoods.com/"),
("000004", "Restaurant Depot",
"1(800)551-4410", "customerservice@restaurantdepot.com",
"https://www.restaurantdepot.com/");

INSERT INTO Item VALUES
("000001", "French Fries", "FROZEN", "lb"),
("000002", "Cheddar Cheese Slice", "REFRIGERATED", "lb"),
("000003", "Ketchup", "DRY FOOD", "gal"),
("000004", "Napkins", "PAPER GOODS", "each"),
("000005", "Mustard", "DRY FOOD", "gal"),
("000006", "Mayonnaise", "DRY FOOD", "gal"),
("000007", "Pickles", "DRY FOOD", "gal"),
("000008", "Burger Buns", "DRY FOOD", "each"),
("000009", "Ground Beef", "MEAT", "lb"),
("000010", "Chicken Breast", "MEAT", "lb"),
("000011", "Lettuce", "PRODUCE", "head"),
("000012", "Tomatoes", "PRODUCE", "lb"),
("000013", "Onions", "PRODUCE", "lb"),
("000014", "Paper Towels", "PAPER GOODS", "roll"),
("000015", "Foam Takeout Containers", "PAPER GOODS", "each" ),
("000016", "Mozzarella Cheese", "REFRIGERATED", "lb"),
("000017", "Bacon", "REFRIGERATED", "lb"),
("000018", "Frozen Chicken Nuggets", "FROZEN", "lb"),
("000019", "Hash Browns", "FROZEN", "lb"),
("000020", "BBQ Sauce", "DRY FOOD", "gal");

INSERT INTO Product (
    vendor_pnum,
    vendor_pname,
    internal_num,
    purchase_unit,
    vendor_num,
    price,
    conversion_factor
) VALUES
("126991260",
"Hellmann's Real Mayonnaise 1 Gallon Jug - 4/Case",
"000006", "4gal", "000001", 61.99, 4.0),

("411pickle01",
"Delancey Hamburger Dill Pickle Slices 1 Gallon Jar - 4/Case",
"000007", "4gal", "000002", 38.49, 4.0),

("900bun001",
"Premium Sesame Hamburger Buns 8 Count - 12/Case",
"000008", "96 each", "000003", 29.99, 96.0),

("beef80193",
"Ground Beef 80/20 Fresh 10 lb. Pack",
"000009", "10lb", "000002", 42.90, 10.0),

("chxbreast1",
"Boneless Skinless Chicken Breast 40 lb. Case",
"000010", "40lb", "000003", 119.99, 40.0),

("lettuce24",
"Iceberg Lettuce 24 Count Case",
"000011", "24 head", "000002", 36.49, 24.0),

("tomroma25",
"Roma Tomatoes 25 lb. Case",
"000012", "25lb", "000003", 31.99, 25.0),

("onion50yel",
"Yellow Onions 50 lb. Bag",
"000013", "50lb", "000004", 24.99, 50.0),

("ptowel030",
"White Paper Towel Rolls - 30/Case",
"000014", "30 rolls", "000001", 25.49, 30.0),

("foam200cl",
"9x9 Foam Hinged Take-Out Containers - 200/Case",
"000015", "200 each", "000004", 18.99, 200.0),

("mzz6132",
"Whole Milk Mozzarella Cheese 6 lb. Loaf - 6/Case",
"000016", "36lb", "000001", 129.99, 36.0),

("bacon15sl",
"Restaurant Style Bacon 15 lb. Case",
"000017", "15lb", "000003", 74.99, 15.0),

("nugget10x2",
"Fully Cooked Breaded Chicken Nuggets 10 lb. - 2/Case",
"000018", "20lb", "000002", 68.99, 20.0),

("hashbrown6",
"Shredded Hash Browns 3 lb. - 6/Case",
"000019", "18lb", "000001", 41.49, 18.0),

("bbq128oz4",
"Sweet Baby Ray's BBQ Sauce 1 Gallon - 4/Case",
"000020", "4gal", "000003", 43.99, 4.0),

("must001alt",
"French's Classic Yellow Mustard 1 Gallon - 4/Case",
"000005", "4gal", "000002", 23.99, 4.0),

("ketchup106",
"Heinz Ketchup 114 oz. Bottle - 6/Case",
"000003", "5.34gal", "000003", 36.99, 5.34),

("napkinbev2",
"Black Beverage Napkins 2-Ply - 1000/Case",
"000004", "1000 napkins", "000004", 14.49, 1000.0),

("friesskinon",
"Skin-On 3/8 in. Frozen Fries 6/5 lb. Case",
"000001", "30lb", "000002", 82.99, 30.0),

("cheddar5lb6",
"Mild Cheddar Cheese 5 lb. Loaf - 6/Case",
"000002", "30lb", "000003", 176.49, 30.0);

INSERT INTO Employee VALUES
("56881", "Jeremy Dickinson", TRUE),
("56882", "John Doe", TRUE),
("56883", "Fran Fine", TRUE),
("56884", "Sam Shrek", FALSE);

CALL addInvoice("8945341", "2025-12-12", "000001");
CALL addInvoiceLine(1, 1, 5, '56882', 20.0);
CALL addInvoiceLine(1, 9, 2, '56881', 22.10);
CALL addInvoiceLine(1, 11, 1, '56882', 35.0);
CALL addInvoiceLine(1, 14, 3, '56881', 9.99);

CALL resolveInvoice(1, 'APPROVED', '56881');

CALL addInvoice("89453412", "2025-12-19", "000002");
CALL addInvoiceLine(2, 2, 1, '56881', 38.49);
CALL addInvoiceLine(2, 4, 10, '56882', 429.00);
CALL addInvoiceLine(2, 19, 20, '56881', 1659.80);
CALL addInvoiceLine(2, 6, 2, '56882', 72.98);
CALL addInvoiceLine(2, 16, 1, '56881', 23.99);
CALL addInvoiceLine(2, 13, 5, '56882', 344.95);

CALL addInvoice("89453413", "2025-12-20", "000003");
CALL addInvoiceLine(3, 3, 5, '56881', 149.95);
CALL addInvoiceLine(3, 12, 15, '56882', 1124.85);
CALL addInvoiceLine(3, 15, 1, '56881', 43.99);
CALL addInvoiceLine(3, 20, 4, '56882', 705.96);
CALL addInvoiceLine(3, 5, 10, '56881', 1199.90);
CALL addInvoiceLine(3, 17, 1, '56882', 36.99);
CALL addInvoiceLine(3, 7, 2, '56881', 63.98);

CALL addInvoice("89453414", "2025-12-24", "000004");
CALL addInvoiceLine(4, 10, 5, '56881', 94.95);
CALL addInvoiceLine(4, 18, 15, '56882', 217.35);

CALL resolveInvoice(3, 'APPROVED', '56881');
CALL resolveInvoice(4, 'APPROVED', '56881');

CALL createUseTransaction(19, 40, '56881');
CALL createAdjustTransaction(19, 40, '56881', 'improper setup');
CALL resolveInventoryTransaction(21, 'APPROVED', '56881');
CALL resolveInventoryTransaction(20, 'APPROVED', '56881');

CALL createWasteTransaction(19, 0.5, '56881', 'dropped on the floor');

CALL createAdjustTransaction(19, -4.6, '56881', 'inventory correction');
CALL resolveInventoryTransaction(22, 'APPROVED', '56881');

SHOW ERRORS;

SELECT * FROM InventoryTransaction
	WHERE transaction_type <> 'RECEIVE';

SELECT * FROM ProductInventory;
SELECT COUNT(*)
FROM ProductInventory;
SHOW ERRORS;