from app.database import get_connection

def get_all_ingredients():
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        query = """
            SELECT
                i.recipe_num,
                i.internal_num,
                it.internal_name AS ingredient_name,
                i.quantity,
                it.internal_unit
            FROM Ingredients AS i
            JOIN Items AS it
                ON i.internal_num = it.internal_num
            ORDER BY i.recipe_num, i.internal_num"""
            ingredients.append(ingredient)
        return ingredients