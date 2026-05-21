from app.database import get_connection


def get_all_products():

    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = """
            SELECT
                p.product_num,
                p.vendor_pnum,
                p.vendor_pname,
                p.purchase_unit,
                p.price,
                p.conversion_factor,
                p.internal_num,
                i.internal_name,
                i.internal_unit,
                v.vendor_num,
                v.vendor_name,
                CAST(COALESCE(pi.quantity, 0) AS DECIMAL(10,3)) AS inventory_quantity
            FROM Product p
            JOIN Item i
                ON p.internal_num = i.internal_num
            JOIN Vendor v
                ON p.vendor_num = v.vendor_num
            LEFT JOIN ProductInventory pi
                ON p.product_num = pi.product_num
            ORDER BY p.product_num;
        """

        cursor.execute(query)

        return cursor.fetchall()

    finally:

        if cursor:
            cursor.close()

        if conn:
            conn.close()


def get_product_by_num(product_num: int):

    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = '''
        SELECT
        p.product_num,
        p.vendor_pnum,
        p.vendor_pname,
        p.purchase_unit,
        p.price,
        p.conversion_factor,
        p.internal_num,
        i.internal_name,
        i.internal_unit,
        v.vendor_num,
        v.vendor_name,
        CAST(COALESCE(pi.quantity, 0) AS DECIMAL(10,3)) AS inventory_quantity
        FROM Product p JOIN Item i
            ON p.internal_num = i.internal_num
        JOIN Vendor v
            ON p.vendor_num = v.vendor_num
        LEFT JOIN ProductInventory pi
            ON p.product_num = pi.product_num
        WHERE p.product_num = %s;
        '''

        cursor.execute(query, (product_num,))

        return cursor.fetchone()

    finally:

        if cursor:
            cursor.close()

        if conn:
            conn.close()