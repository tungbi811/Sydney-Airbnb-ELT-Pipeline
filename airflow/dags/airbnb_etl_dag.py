from airflow.sdk import dag, task
from datetime import datetime, timedelta
from cosmos import DbtTaskGroup, ProjectConfig, ProfileConfig, ExecutionConfig

@dag(
    dag_id="airbnb_etl",
    schedule="@monthly",
    start_date=datetime(2020, 5, 1),
    end_date=datetime(2021,4,1),
    catchup=True,
    max_active_runs=1
)
def airbnb_etl():

    @task
    def load_reference():
        from ingestion.load_reference import load_reference_tables
        load_reference_tables()

    @task
    def load_listings(logical_date=None):
        from ingestion.load_listings import load_listings_table
        load_listings_table(logical_date.strftime("%m_%Y"))

    dbt_transform = DbtTaskGroup(
        group_id='dbt_transform',
        project_config=ProjectConfig("/opt/airflow/dbt/"),
        profile_config=ProfileConfig(
            profile_name="airbnb_analytics",
            target_name='dev',
            profiles_yml_filepath='/opt/airflow/dbt/profiles.yml'
        ),
        execution_config=ExecutionConfig(
            dbt_executable_path='/opt/airflow/dbt_venv/bin/dbt'
        )
    )

    [load_reference(), load_listings()] >> dbt_transform

airbnb_etl()
