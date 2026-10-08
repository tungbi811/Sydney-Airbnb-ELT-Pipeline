-- SCD2 history of the lga entity (int_lga).
-- timestamp strategy: a new version is recorded when scraped_date moves forward (cast to timestamp as scraped_at).

{% snapshot lga_snapshot %}

{{
    config(
        schema='silver',
        unique_key='lga_code',
        strategy='timestamp',
        updated_at='scraped_at'
    )
}}

select *, scraped_date::timestamp as scraped_at  -- snapshots need a timestamp, not a date
from {{ ref('int_lga') }}

{% endsnapshot %}
