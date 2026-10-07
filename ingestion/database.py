import psycopg2

from ingestion.config import (
    POSTGRES_HOST,
    POSTGRES_DATABASE,
    POSTGRES_USER,
    POSTGRES_PASSWORD
)

def get_connection():
    return psycopg2.connect(
        host=POSTGRES_HOST,
        database=POSTGRES_DATABASE,
        user=POSTGRES_USER,
        password=POSTGRES_PASSWORD
    )