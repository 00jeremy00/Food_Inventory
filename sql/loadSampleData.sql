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
("000002", "Milk", "REFRIGERATED", "gallon"),
("000003", "Flour", "DRY FOOD", "lb"),
("000004", "Napkins", "DRY GOODS", "each");


INSERT INTO Product VALUES
("878lamc0057",
"Lamb Weston Colossal Crisp 3/8\" Regular Cut Batter Coated French Fries 5 lb. - 6/Case",
"000001", "5lb bag(6)", "000001", 96.99);
SELECT * FROM Product;