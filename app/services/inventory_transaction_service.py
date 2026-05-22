from app.database import get_connection

def get_all_inventory_transactions(trans_status = None, trans_type = None):
    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = """
            SELECT 
                t.transaction_num,
                t.transaction_type,
                t.quantity,
                t.transaction_date,
                t.approved_by,
                e1.employee_name AS approver_name,
                t.created_by,
                e2.employee_name AS creator_name,
                t.approval_status,
                t.invoice_id,
                t.product_num,
                t.price_per_unit,
                t.batch_num,
                t.reason
            FROM InventoryTransaction as t
            LEFT JOIN Employee e1 ON t.approved_by = e1.employee_num
            LEFT JOIN Employee e2 ON t.created_by = e2.employee_num
            WHERE 1=1
        """
        params = []

        if trans_status:
            query += " AND t.approval_status = %s"
            params.append(trans_status.value)

        if trans_type:
            query += " AND t.transaction_type = %s"
            params.append(trans_type.value)

        query += " ORDER BY t.transaction_date DESC;"

        print(query)

        cursor.execute(query, tuple(params))
        transactions = cursor.fetchall()

    except Exception as e:
        print(f"Error occurred while fetching inventory transactions: {e}")
        transactions = []
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

    return transactions

def get_inventory_transaction_by_num(trans_num):
    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = """
            SELECT 
                t.transaction_num,
                t.transaction_type,
                t.quantity,
                t.transaction_date,
                t.approved_by,
                e1.employee_name AS approver_name,
                t.created_by,
                e2.employee_name AS creator_name,
                t.approval_status,
                t.invoice_id,
                t.product_num,
                t.price_per_unit,
                t.batch_num,
                t.reason
            FROM InventoryTransaction as t
            LEFT JOIN Employee e1 ON t.approved_by = e1.employee_num
            LEFT JOIN Employee e2 ON t.created_by = e2.employee_num
            WHERE t.transaction_num  = %s;
        """

        cursor.execute(query, (trans_num,))
        result = cursor.fetchone()
    except Exception as e:
        print(f"Error occurred while fetching recipes: {e}")
        result = None
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

    return result

