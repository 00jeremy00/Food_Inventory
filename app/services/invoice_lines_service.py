from app.database import get_connection
from typing import Optional

def get_all_invoice_lines(product_num: Optional[int] = None, invoice_id: Optional[int] = None):
    
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        query = """
            SELECT 
                i.invoice_id,
                i.product_num,
                p.vendor_pname,
                p.internal_num,
                i.quantity,
                p.purchase_unit,
                i.line_price
            FROM InvoiceLine AS i
            JOIN Product AS p
                ON i.product_num = p.product_num
            WHERE 1=1 
        """
        params = []
        if product_num is not None:
            query += " AND i.product_num = %s "
            params.append(product_num)
        if invoice_id is not None:
            query += " AND i.invoice_id = %s "
            params.append(invoice_id)
        
        query += " ORDER BY i.invoice_id ASC;"
        cursor.execute(query, tuple(params))
        invoice_lines = cursor.fetchall()
    except Exception as e:
        print(f"Error fetching invoice lines: {e}")
        invoice_lines = []
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

    return invoice_lines
