-- ===============================
-- Invoice 1 (Webstaurant)
-- ===============================

CALL addInvoice("8945341", "2025-12-12", "000001"); -- create Webstaurant invoice
SHOW ERRORS;
CALL addInvoiceLine(1, 1, 5, '56882', 20.0);   -- Mayonnaise: 5 cases (4 gal each → 20 gal total)
CALL addInvoiceLine(1, 9, 2, '56881', 22.10);  -- Paper Towels: 2 cases (30 rolls each → 60 rolls)
CALL addInvoiceLine(1, 11, 1, '56882', 35.0);  -- Mozzarella: 1 case (36 lb total)
CALL addInvoiceLine(1, 14, 3, '56881', 9.99);  -- Hash Browns: 3 cases (18 lb each → 54 lb)

CALL resolveInvoice(1, 'APPROVED', '56881');  


-- ===============================
-- Invoice 2 (Sysco) [LEFT PENDING]
-- ===============================

CALL addInvoice("89453412", "2025-12-19", "000002"); -- create Sysco invoice

CALL addInvoiceLine(2, 2, 1, '56881', 38.49);   -- Pickles: 1 case (4 gal)
CALL addInvoiceLine(2, 4, 10, '56882', 429.00); -- Ground Beef: 10 packs (10 lb each → 100 lb)
CALL addInvoiceLine(2, 19, 20, '56881', 1659.80); -- Fries: 20 cases (30 lb each → 600 lb)
CALL addInvoiceLine(2, 6, 2, '56882', 72.98);   -- Lettuce: 2 cases (24 heads each → 48 heads)
CALL addInvoiceLine(2, 16, 1, '56881', 23.99);  -- Mustard: 1 case (4 gal)
CALL addInvoiceLine(2, 13, 5, '56882', 344.95); -- Nuggets: 5 cases (20 lb each → 100 lb)

-- NOTE: This invoice is intentionally NOT approved yet
-- used to test pending invoice behavior


-- ===============================
-- Invoice 3 (US Foods)
-- ===============================

CALL addInvoice("89453413", "2025-12-20", "000003"); -- create US Foods invoice

CALL addInvoiceLine(3, 3, 5, '56881', 149.95);   -- Buns: 5 cases (96 each → 480 buns)
CALL addInvoiceLine(3, 12, 15, '56882', 1124.85); -- Bacon: 15 cases (15 lb each → 225 lb)
CALL addInvoiceLine(3, 15, 1, '56881', 43.99);   -- BBQ Sauce: 1 case (4 gal)
CALL addInvoiceLine(3, 20, 4, '56882', 705.96);  -- Cheddar Cheese: 4 cases (30 lb each → 120 lb)
CALL addInvoiceLine(3, 5, 10, '56881', 1199.90); -- Chicken Breast: 10 cases (40 lb each → 400 lb)
CALL addInvoiceLine(3, 17, 1, '56882', 36.99);   -- Ketchup: 1 case (~5.34 gal)
CALL addInvoiceLine(3, 7, 2, '56881', 63.98);    -- Tomatoes: 2 cases (25 lb each → 50 lb)

CALL resolveInvoice(3, 'APPROVED', '56881'); 


-- ===============================
-- Invoice 4 (Restaurant Depot)
-- ===============================

CALL addInvoice("89453414", "2025-12-24", "000004"); -- create Restaurant Depot invoice

CALL addInvoiceLine(4, 10, 5, '56881', 94.95); -- Onions: 5 bags (50 lb each → 250 lb)
CALL addInvoiceLine(4, 18, 15, '56882', 217.35); -- Napkins: 15 cases (1000 each → 15,000 napkins)

CALL resolveInvoice(4, 'APPROVED', '56881'); 

SELECT * FROM InventoryTransaction;
SELECT * FROM ProductInventory;
SELECT * FROM Invoice;
SELECT * FROM Vendor;
SELECT * FROM Product;