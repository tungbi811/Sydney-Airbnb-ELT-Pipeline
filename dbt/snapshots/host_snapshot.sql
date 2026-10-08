-- SCD2 history of the host entity (int_host).
-- timestamp strategy: a new version is recorded when scraped_date moves forward (cast to timestamp as scraped_at).

{% snapshot host_snapshot %}

{{
    config(
        schema='silver',
        unique_key='host_id',
        strategy='timestamp',
        updated_at='scraped_at'
    )
}}

select *, scraped_date::timestamp as scraped_at  -- snapshots need a timestamp, not a date
from {{ ref('int_host') }}

{% endsnapshot %}
