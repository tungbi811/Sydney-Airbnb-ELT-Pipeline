from io import TextIOWrapper

from ingestion.config import S3_BUCKET
from ingestion.database import get_connection
from ingestion.s3 import s3, list_csv_files

LISTINGS_FOLDER = "listings/"
LISTINGS_TABLE = "bronze.listings"

def file_already_loaded(cur, file_name):
    cur.execute('SELECT EXISTS (SELECT 1 FROM bronze.listings WHERE source_file = %s)', (file_name, ))
    
    return cur.fetchone()[0]

def load_listing_file(cur, file_name):
    if file_already_loaded(cur, file_name):
        print(f"Skipping {file_name}: already loaded")
        return

    print(f'Loading {file_name}')

    cur.execute("CREATE TEMP TABLE staging_listings (LIKE bronze.listings) ON COMMIT DROP")

    obj = s3.get_object(Bucket=S3_BUCKET, Key=file_name)

    with TextIOWrapper(obj['Body'], encoding='utf-8') as f:
        cur.copy_expert(
            """
            COPY staging_listings (
                listing_id,
                scrape_id,
                scraped_date,
                host_id,
                host_name,
                host_since,
                host_is_superhost,
                host_neighbourhood,
                listing_neighbourhood,
                property_type,
                room_type,
                accommodates,
                price,
                has_availability,
                availability_30,
                number_of_reviews,
                review_scores_rating,
                review_scores_accuracy,
                review_scores_cleanliness,
                review_scores_checkin,
                review_scores_communication,
                review_scores_value
            )
            FROM STDIN
            WITH (
                FORMAT CSV,
                HEADER TRUE
            )
            """,
            f
        )

        cur.execute(
            """
            INSERT INTO bronze.listings
            SELECT
                listing_id,
                scrape_id,
                scraped_date,
                host_id,
                host_name,
                host_since,
                host_is_superhost,
                host_neighbourhood,
                listing_neighbourhood,
                property_type,
                room_type,
                accommodates,
                price,
                has_availability,
                availability_30,
                number_of_reviews,
                review_scores_rating,
                review_scores_accuracy,
                review_scores_cleanliness,
                review_scores_checkin,
                review_scores_communication,
                review_scores_value,
                %s
            FROM staging_listings
            """,
            (file_name,)
        )

def load_listings():
    conn = get_connection()

    try:
        listing_files = list_csv_files(S3_BUCKET, LISTINGS_FOLDER)

        print(f'Found {len(listing_files)} listing files')

        cur = conn.cursor()

        for file in listing_files:
            load_listing_file(cur, file)

        conn.commit()

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()

if __name__ == '__main__':
    load_listings()