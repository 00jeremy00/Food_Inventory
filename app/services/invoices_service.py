from app.database import get_connection
from app.enums import ApprovalStatus

def get_all_invoices(approval_status: ApprovalStatus = None):
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
                v.vendor_name,
                i.approval_status,
                i.approved_by,
                e.employee_name AS approved_by_name
            FROM Invoice as i
            LEFT JOIN Employee AS e
                ON i.approved_by = e.employee_num
            LEFT JOIN Vendor AS v
                ON i.vendor_num = v.vendor_num
            WHERE 1=1 """
        params = []
        if approval_status:
            query += "AND i.approval_status = %s "
            params.append(approval_status)
        
        query += "ORDER BY i.invoice_date ASC;"
        print(f"Executing query: {query} with params: {params}")
        cursor.execute(query, tuple(params) if params else None)
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
                v.vendor_name,
                i.approval_status,
                i.approved_by,
                e.employee_name AS approved_by_name
            FROM Invoice as i
            LEFT JOIN Employee AS e
                ON i.approved_by = e.employee_num
            LEFT JOIN Vendor AS v
                ON i.vendor_num = v.vendor_num
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