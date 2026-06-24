import mysql.connector
from app.config import DB_CONFIG


def get_connection():

    return mysql.connector.connect(
        user=DB_CONFIG["user"],
        password=DB_CONFIG["password"],
        database=DB_CONFIG["database"],
        unix_socket="/var/run/mysqld/mysqld.sock",
        autocommit=False,
        use_pure=True
    )
