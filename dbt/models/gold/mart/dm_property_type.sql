-- Monthly KPIs per property_type, room_type and accommodates.
-- Facts are joined to the SCD2 dimensions on key + listing_month, so each month uses the
-- property / host attributes that were valid at that time.

with listings as (
    select
        p.property_type,
        p.room_type,
        p.accommodates,
        f.listing_month,
        f.listing_id,
        f.host_id,
        h.host_is_superhost,
        f.has_availability,
        f.price,
        f.review_scores_rating,
        f.number_of_stays,
        f.estimated_revenue
    from {{ ref('fact_listings') }} f
    join {{ ref('dim_property') }} p
        on  f.listing_id = p.listing_id
        and f.listing_month >= p.valid_from
        and (p.valid_to is null or f.listing_month < p.valid_to)
    join {{ ref('dim_host') }} h
        on  f.host_id = h.host_id
        and f.listing_month >= h.valid_from
        and (h.valid_to is null or f.listing_month < h.valid_to)
),

monthly as (
    select
        property_type,
        room_type,
        accommodates,
        listing_month,
        count(*)                                                                as total_listings,
        count(*) filter (where has_availability)                                as active_listings,
        count(*) filter (where not has_availability)                            as inactive_listings,
        min(price) filter (where has_availability)                              as min_price,
        max(price) filter (where has_availability)                              as max_price,
        percentile_cont(0.5) within group (order by price)
            filter (where has_availability)                                     as median_price,
        avg(price) filter (where has_availability)                              as avg_price,
        count(distinct host_id)                                                 as distinct_hosts,
        count(distinct host_id) filter (where host_is_superhost)                as distinct_superhosts,
        avg(review_scores_rating) filter (where has_availability)               as avg_review_scores_rating,
        sum(number_of_stays)                                                    as total_stays,    -- 0 for inactive listings
        sum(estimated_revenue)                                                  as total_estimated_revenue
    from listings
    group by property_type, room_type, accommodates, listing_month
)

select
    property_type,
    room_type,
    accommodates,
    listing_month,
    round(100.0 * active_listings / total_listings, 2)                          as active_listings_rate,
    round(min_price, 2)                                                         as min_price,
    round(max_price, 2)                                                         as max_price,
    round(median_price::numeric, 2)                                             as median_price,
    round(avg_price, 2)                                                         as avg_price,
    distinct_hosts,
    round(100.0 * distinct_superhosts / distinct_hosts, 2)                      as superhost_rate,
    round(avg_review_scores_rating, 2)                                          as avg_review_scores_rating,
    -- month-to-month % change; NULL for the first month or when the previous month is 0
    round(100.0 * (active_listings - lag(active_listings) over w)
          / nullif(lag(active_listings) over w, 0), 2)                          as active_listings_pct_change,
    round(100.0 * (inactive_listings - lag(inactive_listings) over w)
          / nullif(lag(inactive_listings) over w, 0), 2)                        as inactive_listings_pct_change,
    total_stays,
    round(total_estimated_revenue / nullif(active_listings, 0), 2)              as avg_estimated_revenue_per_active_listing
from monthly
window w as (partition by property_type, room_type, accommodates order by listing_month)
order by property_type, room_type, accommodates, listing_month
