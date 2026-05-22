from app.database import get_connection

def get_all_batch_transactions(trans_status, trans_type):
    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query =   """SELECT
                b.transaction_num,
                b.batch_num,
                b.quantity,
                b.transaction_type,
                b.transaction_date,
                b.created_by,
                e.employee_name AS creator_name,
                b.created_by,
                b.approved_by,
                e2.employee_name AS approver_name,
                b.approval_status,
				b.reason
            FROM BatchTransaction AS b
            LEFT JOIN Employee AS e ON b.created_by = e.employee_num
            LEFT JOIN Employee AS e2 ON b.approved_by = e2.employee_num
            WHERE 1=1"""
        
        params = []
        
        if trans_status:
            query += " AND b.approval_status = %s"
            params.append(trans_status) 
        if trans_type:
            query += " AND b.transaction_type = %s"
            params.append(trans_type)

        query += " ORDER BY b.transaction_date DESC;"

        cursor.execute(query, tuple(params))
        batch_transactions = cursor.fetchall()
    except Exception as e:
        print(f"Error occurred while fetching batch transactions: {e}")
        batch_transactions = []
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

    print("EXECUTING QUERY: ", query)
    return batch_transactions

def get_batch_transaction_by_num(trans_num):
    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query =   """SELECT
                b.transaction_num,
                b.batch_num,
                b.quantity,
                b.transaction_type,
                b.transaction_date,
                b.created_by,
                e.employee_name AS creator_name,
                b.created_by,
                b.approved_by,
                e2.employee_name AS approver_name,
                b.approval_status,
                b.reason
            FROM BatchTransaction AS b
            LEFT JOIN Employee AS e ON b.created_by = e.employee_num
            LEFT JOIN Employee AS e2 ON b.approved_by = e2.employee_num
            WHERE b.transaction_num = %s;"""
        
        cursor.execute(query, (trans_num,))
        batch_transaction = cursor.fetchone()
    except Exception as e:
        print(f"Error occurred while fetching batch transaction: {e}")
        batch_transaction = None
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

    return batch_transaction