-- Q(d): for hosts with multiple listings, are their listings concentrated in one LGA
-- or distributed across several? One row per multi-listing host.

with host_listings as (
    select
        host_id,
        count(distinct listing_id) as listings,
        count(distinct lga_code)   as lgas
    from {{ ref('fact_listings') }}
    group by host_id
)

select
    host_id,
    listings,
    lgas,
    case when lgas = 1 then 'concentrated' else 'distributed' end as spread
from host_listings
where listings > 1
