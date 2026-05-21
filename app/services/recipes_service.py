from app.database import get_connection

def get_all_recipes():
    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = """
            SELECT
                recipe_num,
                recipe_name,
                recipe_status,
                shelflife,
                yield,
                recipe_unit
            FROM Recipe
            ORDER BY recipe_num;"""
        
        cursor.execute(query)
        recipes = cursor.fetchall()
    except Exception as e:
        print(f"Error occurred while fetching recipes: {e}")
        recipes = []
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

    return recipes