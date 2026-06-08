from app.database import get_connection
def get_all_batches():
    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = """
            SELECT 
            	b.batch_num,
                r.recipe_num,
                r.recipe_name,
                b.created_on,
                b.created_by,
                e.employee_name AS created_by_name,
                b.approved_by,
                e2.employee_name AS approved_by_name,
                b.plan_num,
                b.prepared_quantity,
                b.remaining_quantity,
                r.recipe_unit,
                b.depleted_at,
                b.expires_at,
                b.batch_status
            FROM Batch b
            JOIN Recipe r ON b.recipe_num = r.recipe_num
            LEFT JOIN Employee e ON b.created_by = e.employee_num
            LEFT JOIN Employee e2 ON b.approved_by = e2.employee_num
            ORDER BY b.created_on DESC;
            
        """

        cursor.execute(query)

        return cursor.fetchall()
    finally:
        if cursor:
            cursor.close()
        
        if conn:
            conn.close()

def get_batch_by_num(batch_num):
    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = """
            SELECT 
            	b.batch_num,
                r.recipe_num,
                r.recipe_name,
                b.created_on,
                b.created_by,
                e.employee_name AS created_by_name,
                b.approved_by,
                e2.employee_name AS approved_by_name,
                b.plan_num,
                b.prepared_quantity,
                b.remaining_quantity,
                r.recipe_unit,
                b.depleted_at,
                b.expires_at,
                b.batch_status
            FROM Batch b
            JOIN Recipe r ON b.recipe_num = r.recipe_num
            LEFT JOIN Employee e ON b.created_by = e.employee_num
            LEFT JOIN Employee e2 ON b.approved_by = e2.employee_num
            WHERE b.batch_num = %s;
        """
        cursor.execute(query, (batch_num,))
        return cursor.fetchone()
    finally:
        if cursor:
            cursor.close()
        
        if conn:
            conn.close()

def get_active_batches():
    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = """
            SELECT 
            	b.batch_num,
                r.recipe_num,
                r.recipe_name,
                b.created_on,
                b.created_by,
                e.employee_name AS created_by_name,
                b.approved_by,
                b.plan_num,
                b.prepared_quantity,
                b.remaining_quantity,
                b.depleted_at,
                b.expires_at,
                b.batch_status
            FROM Batch b
            JOIN Recipe AS r ON b.recipe_num = r.recipe_num
            LEFT JOIN Employee AS e ON b.created_by = e.employee_num
            WHERE b.batch_status = 'ACTIVE'
            ORDER BY b.created_on DESC;
        """
        cursor.execute(query)
        return cursor.fetchall()
    finally:
        if cursor:
            cursor.close()
        
        if conn:
            conn.close()

def get_pending_batches():
    conn = None
    cursor = None
    
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = """
            SELECT 
            	b.batch_num,
                r.recipe_num,
                r.recipe_name,
                b.created_on,
                b.created_by,
                e.employee_name AS created_by_name,
                b.approved_by,
                b.plan_num,
                b.prepared_quantity,
                b.remaining_quantity,
                b.depleted_at,
                b.expires_at,
                b.batch_status
            FROM Batch b
            JOIN Recipe AS r ON b.recipe_num = r.recipe_num
            LEFT JOIN Employee AS e ON b.created_by = e.employee_num
            WHERE b.batch_status = 'PENDING'
            ORDER BY b.created_on DESC;
        """
        cursor.execute(query)
        return cursor.fetchall()
    finally:
        if cursor:
            cursor.close()
        
        if conn:
            conn.close()