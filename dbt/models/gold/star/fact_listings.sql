-- Listing fact: one row per listing per month. Only keys, the date and metrics;
-- descriptive attributes come from the SCD2 dimensions joined on key + listing_month.

select
    l.listing_id,                                           -- -> dim_property
    l.host_id,                                              -- -> dim_host
    c.lga_code,                                             -- -> dim_lga (listing_neighbourhood)
    l.listing_month,
    l.scraped_date,
    l.price,
    l.has_availability,
    l.availability_30,
    -- stays and revenue only count for active listings (has_availability = 't')
    case when l.has_availability then 30 - l.availability_30 else 0 end            as number_of_stays,
    case when l.has_availability then (30 - l.availability_30) * l.price else 0 end as estimated_revenue,
    l.number_of_reviews,
    l.review_scores_rating
from {{ ref('stg_listings') }} l
left join {{ ref('stg_lga_codes') }} c
    on upper(l.listing_neighbourhood) = upper(c.lga_name)
