USE FOOD;
INSERT INTO Category VALUES
('REFRIGERATED'),
('DRY FOOD'),
('FROZEN'),
("PRODUCE"),
("MEAT"),
("PAPER GOODS");

INSERT INTO Shift VALUES
("First Shift", "06:00:00", "14:00:00"),
("Second Shift", "14:00:00", "22:00:00"),
("FULL", "00:00:00", "23:59:59");


CALL addVendor("000001", "Webstaraunt", "717-657-8931", "support@webstaraunt.com",
"https://www.webstaurant.com");

CALL addVendor("000002", "Sysco",
"1(281)584-1300", "support@sysco.com",
"https://www.sysco.com/");

CALL addVendor("000003", "US Foods",
"1(847)720-8000", "info@usfoods.com",
"https://www.usfoods.com/");

CALL addVendor("000004", "Restaurant Depot",
"1(800)551-4410", "customerservice@restaurantdepot.com",
"https://www.restaurantdepot.com/");

INSERT INTO Employee VALUES
("56881", "Jeremy Dickinson", TRUE),
("56882", "John Doe", TRUE),
("56883", "Fran Fine", TRUE),
("56884", "Sam Shrek", FALSE);