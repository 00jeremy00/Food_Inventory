from app.database import get_connection

def get_all_invoices():
    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        query = """
            SELECT 
                i.invoice_id,
                i.invoice_num,
                i.invoice_date,
                i.vendor_num,
                i.approval_status,
                i.approved_by,
                e.employee_name AS approved_by_name
            FROM Invoice as i
            LEFT JOIN Employee AS e
                ON i.approved_by = e.employee_num
            ORDER BY i.invoice_date ASC;"""

        cursor.execute(query)
        invoices = cursor.fetchall()
    
    except Exception as e:
        print(f"Error fetching invoices: {e}")
        invoices = []
    
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
    return invoices

def get_invoice_by_num(invoice_num: str):
    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        query = """
            SELECT 
                i.invoice_id,
                i.invoice_num,
                i.invoice_date,
                i.vendor_num,
                i.approval_status,
                i.approved_by,
                e.employee_name AS approved_by_name
            FROM Invoice as i
            LEFT JOIN Employee AS e
                ON i.approved_by = e.employee_num
            WHERE i.invoice_id = %s;"""

        cursor.execute(query, (invoice_num,))
        invoice = cursor.fetchone()
    
    except Exception as e:
        print(f"Error fetching invoice: {e}")
        invoice = None
    
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
    return invoice