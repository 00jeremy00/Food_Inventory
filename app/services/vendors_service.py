from app.database import get_connection

def get_all_vendors():
    
    conn=None
    cursor=None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = '''
            SELECT * FROM Vendor
            ORDER BY vendor_num;
        '''
        cursor.execute(query)
        return cursor.fetchall()
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

def get_vendor_by_num(vendor_num):
    conn=None
    cursor=None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = '''
            SELECT * FROM Vendor
            WHERE vendor_num = %s
            LIMIT 1;
        '''
        cursor.execute(query, (vendor_num,))
        return cursor.fetchone()
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()