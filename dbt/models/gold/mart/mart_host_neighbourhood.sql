-- Monthly host revenue KPIs per host_neighbourhood_lga (the LGA of the host's suburb).
-- Hosts whose host_neighbourhood is blank or unmappable (e.g. 'Overseas') are grouped as 'Unknown'.

with listings as (
    select
        coalesce(h.host_neighbourhood_lga, 'Unknown')   as host_neighbourhood_lga,
        f.listing_month,
        f.host_id,
        f.has_availability,
        f.estimated_revenue
    from {{ ref('fact_listings') }} f
    join {{ ref('dim_host') }} h
        on  f.host_id = h.host_id
        and f.listing_month >= h.valid_from
        and (h.valid_to is null or f.listing_month < h.valid_to)
),

monthly as (
    select
        host_neighbourhood_lga,
        listing_month,
        count(distinct host_id)                     as distinct_hosts,
        count(*) filter (where has_availability)    as active_listings,
        sum(estimated_revenue)                      as total_estimated_revenue    -- 0 for inactive listings
    from listings
    group by host_neighbourhood_lga, listing_month
)

select
    host_neighbourhood_lga,
    listing_month,
    distinct_hosts,
    round(total_estimated_revenue / nullif(active_listings, 0), 2)  as avg_estimated_revenue_per_active_listing,
    round(total_estimated_revenue / distinct_hosts, 2)              as estimated_revenue_per_host
from monthly
order by host_neighbourhood_lga, listing_month
