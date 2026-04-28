CALL modifyBatch(1, 2, 'WASTE', 'Wrong Customer', "56881");
CALL modifyBatch(2, 16, 'WASTE', 'Fell out on the floor', "56881");
CALL modifyBatch(1, 2, 'WASTE', 'Over-cooked in fryer', "56881");


SHOW ERRORS;
SELECT * FROM BatchTransaction;