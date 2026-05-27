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
            FROM Ingredient AS i
            JOIN Item AS it
                ON i.internal_num = it.internal_num
            ORDER BY i.recipe_num, i.internal_num;"""
            
        cursor.execute(query)
        ingredients = cursor.fetchall()
    except Exception as e:
        print(f"Error fetching ingredients: {e}")
        ingredients = []
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

    return ingredients