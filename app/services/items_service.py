from app.database import get_connection

def get_all_items():

    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = """
            SELECT *
            FROM ItemInventoryData;
        """

        cursor.execute(query)

        return cursor.fetchall()

    finally:

        if cursor:
            cursor.close()

        if conn:
            conn.close()


def get_item_by_num(internal_num: str):
    
    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = """
            SELECT *
            FROM ItemInventoryData
            WHERE internal_num = %s;
        """

        cursor.execute(query, (internal_num,))

        return cursor.fetchone()

    finally:

        if cursor:
            cursor.close()

        if conn:
            conn.close()