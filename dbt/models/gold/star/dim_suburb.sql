-- Suburb dimension (SCD Type 2) for host_neighbourhood, with the LGA each suburb belongs to.

select
    dbt_scd_id                                  as suburb_sk,
    suburb_name,
    lga_code,
    lga_name,
    date_trunc('month', dbt_valid_from)::date   as valid_from,
    date_trunc('month', dbt_valid_to)::date     as valid_to,      -- NULL = current version
    dbt_valid_to is null                        as is_current
from {{ ref('suburb_snapshot') }}
