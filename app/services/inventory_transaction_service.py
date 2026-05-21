from app.database import get_connection

def get_all_inventory_transactions():
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
            JOIN Employee e1 ON t.approved_by = e1.employee_num
            JOIN Employee e2 ON t.created_by = e2.employee_num
            ORDER BY t.transaction_date DESC;
        """

        cursor.execute(query)
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