from airflow.sdk import dag, task
from datetime import datetime, timedelta

@dag(
    dag_id="airbnb_bronze_load",
    schedule=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    default_args={"retries": 1, "retry_delay": timedelta(minutes=2)},
    tags=['airbnb', 'bronze']
)
def airbnb_bronze_load():

    @task
    def load_reference_task():
        from ingestion.load_reference import load_reference_tables
        load_reference_tables()

    @task
    def load_listings_task():
        from ingestion.load_listings import load_listings_table
        load_listings_table()

    load_reference_task() >> load_listings_task()

airbnb_bronze_load()
