-- Host dimension (SCD Type 2), one row per version of each host.
-- Built from host_snapshot; facts join on host_id + listing_month within [valid_from, valid_to).
--
-- Validity is truncated to the month because a host's version starts at the scraped_date of
-- their latest listing, while their other listings in the same month can be scraped earlier.

select
    dbt_scd_id                                  as host_sk,       -- unique per version
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    host_neighbourhood,
    host_neighbourhood_lga_code,
    host_neighbourhood_lga,
    date_trunc('month', dbt_valid_from)::date   as valid_from,
    date_trunc('month', dbt_valid_to)::date     as valid_to,      -- NULL = current version
    dbt_valid_to is null                        as is_current
from {{ ref('host_snapshot') }}
