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

    t.product_num,
    p.vendor_pname,

    i.internal_num,
    i.internal_name,
    i.internal_unit,

    t.approved_by,
    e1.employee_name AS approver_name,

    t.created_by,
    e2.employee_name AS creator_name,

    t.approval_status,
    t.invoice_id,
    t.price_per_unit,
    t.batch_num,
    t.reason
FROM InventoryTransaction AS t
LEFT JOIN Product AS p
    ON t.product_num = p.product_num
LEFT JOIN Item AS i
    ON p.internal_num = i.internal_num
LEFT JOIN Employee AS e1
    ON t.approved_by = e1.employee_num
LEFT JOIN Employee AS e2
    ON t.created_by = e2.employee_num
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
            t.product_num,
            p.vendor_pname,

            i.internal_num,
            i.internal_name,
            i.internal_unit,

            t.approved_by,
            e1.employee_name AS approver_name,
            t.created_by,
            e2.employee_name AS creator_name,

            t.approval_status,
            t.invoice_id,
            t.price_per_unit,
            t.batch_num,
            t.reason
        FROM InventoryTransaction AS t
        LEFT JOIN Product AS p
            ON t.product_num = p.product_num
        LEFT JOIN Item AS i
            ON p.internal_num = i.internal_num
        LEFT JOIN Employee AS e1
        ON t.approved_by = e1.employee_num
        LEFT JOIN Employee AS e2
            ON t.created_by = e2.employee_num
        WHERE t.transaction_num = %s;
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

def approve_inventory_transaction(trans_num, approver_num):
    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor()

        manager_found = cursor.execute("SELECT * FROM Employee WHERE employee_num = %s AND is_manager = TRUE", (approver_num,))

        if not manager_found:
            raise Exception("Approver is not a manager.")
        
        update_query = """
        UPDATE InventoryTransaction
        SET approval_status = 'APPROVED', approved_by = %s
        WHERE transaction_num = %s;
        """

        cursor.execute(update_query, (approver_num, trans_num))
        conn.commit()
    except Exception as e:
        print(f"Error occurred while approving inventory transaction: {e}")
        if conn:
            conn.rollback()
        raise e
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()