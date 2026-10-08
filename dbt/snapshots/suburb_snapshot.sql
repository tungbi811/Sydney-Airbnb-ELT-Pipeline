-- SCD2 history of the suburb entity (int_suburb).
-- timestamp strategy: a new version is recorded when scraped_date moves forward (cast to timestamp as scraped_at).

{% snapshot suburb_snapshot %}

{{
    config(
        schema='silver',
        unique_key='suburb_name',
        strategy='timestamp',
        updated_at='scraped_at'
    )
}}

select *, scraped_date::timestamp as scraped_at  -- snapshots need a timestamp, not a date
from {{ ref('int_suburb') }}

{% endsnapshot %}
