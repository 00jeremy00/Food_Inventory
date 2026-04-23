CALL addRecipe("Cheese-Burger", 4, 1, "count");
CALL addIngredient("000002", 1, 1);
CALL addIngredient("000003", 1, .01);
CALL addIngredient("000007", 1, .01);
CALL addIngredient("000008", 1, 2);
CALL addIngredient("000009", 1, .25);
CALL addIngredient("000012", 1, .1);

CALL addRecipe("Loaded Fry", .5, 4, "oz");
CALL addIngredient("000001", 2, .25);
CALL addIngredient("000017", 2, .1);
CALL addIngredient("000003", 2, .01);

CALL addRecipe("Chicken Basket", 4, 1, "count");
CALL addIngredient("000001", 3, .25);
CALL addIngredient("000018", 3, .5);
CALL addIngredient("000020", 3, .01);

UPDATE Recipe
SET recipe_status = 'ACTIVE'
WHERE recipe_num = 1;

UPDATE Recipe
SET recipe_status = 'ACTIVE'
WHERE recipe_num = 2;

UPDATE Recipe
SET recipe_status = 'ACTIVE'
WHERE recipe_num = 3;

SELECT * FROM Recipe;