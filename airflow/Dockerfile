FROM apache/airflow:3.3.2

# Cosmos runs inside Airflow's own Python
RUN pip install --no-cache-dir astronomer-cosmos

# dbt gets its own venv so its dependencies don't clash with Airflow's
RUN python -m venv /opt/airflow/dbt_venv && \
    /opt/airflow/dbt_venv/bin/pip install --no-cache-dir \
        dbt-core==1.12.5 dbt-postgres==1.11.0