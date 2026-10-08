-- Property dimension (SCD Type 2), one row per version of each listing's physical attributes.
-- Same validity rules as dim_host: month-truncated [valid_from, valid_to).

select
    dbt_scd_id                                  as property_sk,
    listing_id,
    property_type,
    room_type,
    accommodates,
    date_trunc('month', dbt_valid_from)::date   as valid_from,
    date_trunc('month', dbt_valid_to)::date     as valid_to,      -- NULL = current version
    dbt_valid_to is null                        as is_current
from {{ ref('property_snapshot') }}
