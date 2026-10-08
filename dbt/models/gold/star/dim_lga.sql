-- LGA dimension (SCD Type 2) for listing_neighbourhood. lga_code joins to the census tables.

select
    dbt_scd_id                                  as lga_sk,
    lga_code,
    lga_name,
    date_trunc('month', dbt_valid_from)::date   as valid_from,
    date_trunc('month', dbt_valid_to)::date     as valid_to,      -- NULL = current version
    dbt_valid_to is null                        as is_current
from {{ ref('lga_snapshot') }}
