USE FOOD;
INSERT INTO Category VALUES
("FROZEN"),
("REFRIGERATED"),
("DRY FOOD"),
("DRY GOODS");

INSERT INTO Vendor VALUES
("000001", "Webstaurant",
"1(717)392-7472", "Customizable@WebstaurantStore.com",
 "https://www.webstaurantstore.com/");
 
INSERT INTO Item VALUES
("000001", "LWCC Battered French Fries", "FROZEN", "lb"),
("000002", "Cooper American Cheese Slices", "REFRIGERATED", "lb"),
("000003", "Ketchup", "DRY FOOD", "gal"),
("000004", "Napkins", "DRY GOODS", "each");


INSERT INTO Product VALUES
("878lamc0057",
"Lamb Weston Colossal Crisp 3/8\" Regular Cut Batter Coated French Fries 5 lb. - 6/Case",
"000001", "5lb bag(6)", "000001", 96.99, 30.0),
("875RE9622", "Cooper Cheese CV 5 lb. Sharp Yellow American Cheese - 6/Case",
"000002", "30lb", "000001", 182.49, 30.0),
("125hnz5501", "Heinz 1.5 Gallon Ketchup Dispensing Pouch with Fitment - 2/Case",
"000003", "3gal", "000001", 72.49, 3.0),
("5002bnapwh", "Choice 2-Ply White Customizable Beverage / Cocktail Napkin - 3,000/Case",
"000004", "3000 napkins", "000001", 32.49, 3000);

INSERT INTO Invoice VALUES
("38115699", "2026-03-06", "000001"),
("38115702", "2026-03-08", "000001");

INSERT INTO InvoiceLine VALUES
("38115699","878lamc0057", 2),
("38115699","875RE9622", 3),
("38115699","125hnz5501", 1),
("38115699","5002bnapwh", 4),
("38115702", "5002bnapwh", 50);

INSERT INTO Managers VALUES
("56881", "Jeremy Dickinson"),
("56882", "John Doe");

INSERT INTO InventoryTransaction VALUES
("0000000001", "000002", "RECEIVE", 50, "2026-03-06 23:00:00", "56881", "38115699", NULL)
("0000000003", "000002", "RECEIVE", 50, "2026-03-06 23:00:00", "56881", "38115699", NULL);


SELECT * FROM Inventory;