CALL addRecipe("Cheese-Burger", 4, 1, "count");
CALL addIngredient("000002", 1, 1);					-- adds cheese as ingredient
CALL addIngredient("000003", 1, .01);				-- ketchup
CALL addIngredient("000007", 1, .01);				-- pickles
CALL addIngredient("000008", 1, 2);					-- buns
CALL addIngredient("000009", 1, .25);				-- beef
CALL addIngredient("000012", 1, .1);				-- tomatoes
	
UPDATE Recipe										-- activates cheesburger recipe
SET recipe_status = 'ACTIVE'
WHERE recipe_num = 1;

CALL addRecipe("Loaded Fry", .5, 4, "oz");
CALL addIngredient("000001", 2, .25);				-- fries
CALL addIngredient("000017", 2, .1);				-- bacon
CALL addIngredient("000003", 2, .01);				-- ketchup

SELECT * FROM Item
WHERE internal_num  IN ("000001", "000017", "000003");

UPDATE Recipe										-- activates loaded fry recipe
SET recipe_status = 'ACTIVE'
WHERE recipe_num = 2;

CALL addRecipe("Chicken Basket", 4, 1, "count");
CALL addIngredient("000001", 3, .25);				-- fries
CALL addIngredient("000018", 3, .5);				-- chicken nuggets
CALL addIngredient("000020", 3, .01);				-- BBQ sauce

UPDATE Recipe										-- activates chicken basket recipe
SET recipe_status = 'ACTIVE'
WHERE recipe_num = 3;

SELECT * FROM Ingredient as i
JOIN Product as p
ON p.internal_num = i.internal_num
	WHERE recipe_num = 2;
SELECT * FROM Item;

SELECT * FROM Recipe;