
-- Tests inserting WASTE batch transactions
CALL modifyBatch(1, 2, 'WASTE', 'Wrong Customer', "56881");
CALL modifyBatch(2, 16, 'WASTE', 'Fell out on the floor', "56881");
CALL modifyBatch(1, 2, 'WASTE', 'Over-cooked in fryer', "56881");


CALL modifyBatch(3, 1, 'ADJUST', 'Mislabled Product', "56881");
CALL modifyBatch(3, 2, 'ADJUST', 'Training', "56881");
CALL modifyBatch(3, 3, 'ADJUST', 'Par misread', "56881");

CALL resolveBatchModify(1,'56881', 'APPROVED');
CALL resolveBatchModify(4, '56881', 'APPROVED');
SHOW ERRORS;

-- CALL useBatch(1, 20, "56881");
SHOW ERRORS;

SELECT * FROM Recipe;

CALL useRecipe(1,2, '56881');
SHOW ERRORS;
SELECT * FROM Batch
	WHERE batch_num = 3;

SHOW ERRORS;
SELECT * FROM BatchTransaction;