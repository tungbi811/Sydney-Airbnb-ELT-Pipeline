import csv
from io import TextIOWrapper, StringIO

from ingestion.config import S3_BUCKET
from ingestion.database import get_connection
from ingestion.s3 import s3, file_exists

REFERENCE_TABLES = {
    "census/2016Census_G01_NSW_LGA.csv": "bronze.census_g01",
    "census/2016Census_G02_NSW_LGA.csv": "bronze.census_g02",
    "suburb/NSW_LGA_CODE.csv": "bronze.lga_codes",
    "suburb/NSW_LGA_SUBURB.csv": "bronze.suburb_lga_mapping",
}

def load_reference_tables():
    conn = get_connection()

    try:
        cur = conn.cursor()

        for file_name, table_name in REFERENCE_TABLES.items():

            if not file_exists(S3_BUCKET, file_name):
                print(f"Skipping {file_name}: file not found")
                continue

            print(f'Loading {file_name} -> {table_name}')

            obj = s3.get_object(Bucket=S3_BUCKET, Key=file_name)

            with TextIOWrapper(obj["Body"], encoding='utf-8') as f:
                if table_name == "bronze.suburb_lga_mapping":
                    cleaned = StringIO()
                    writer = csv.writer(cleaned)

                    for row in csv.reader(f):
                        if any(row[2:]):
                            raise ValueError(
                                "Unexpected nonempty fields after the first two columns"
                            )

                        writer.writerow(row[:2])

                    cleaned.seek(0)

                    cur.copy_expert(
                        f"COPY {table_name} FROM STDIN WITH (FORMAT CSV, HEADER TRUE)",
                        cleaned,
                    )
                cur.copy_expert(f"COPY {table_name} FROM STDIN WITH (FORMAT CSV, HEADER TRUE)", f)

        conn.commit()

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()

if __name__ == "__main__":
    load_reference_tables()