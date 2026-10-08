-- Q(c): for the top 5 LGAs by estimated revenue per active listing, which listing type
-- (property type, room type, accommodates) has the highest number of stays?

with lga_revenue as (
    select
        lga_code,
        sum(estimated_revenue)::numeric
            / count(distinct listing_id) filter (where has_availability) as revenue_per_active_listing
    from {{ ref('fact_listings') }}
    group by lga_code
),

top_lgas as (
    select lga_code
    from lga_revenue
    order by revenue_per_active_listing desc
    limit 5
),

listing_type_stays as (
    select
        f.lga_code,
        p.property_type,
        p.room_type,
        p.accommodates,
        sum(f.number_of_stays)              as total_stays,
        count(distinct f.listing_id)        as listings
    from {{ ref('fact_listings') }} f
    join top_lgas t
        on t.lga_code = f.lga_code
    -- property attributes as they were in that month (SCD2)
    join {{ ref('dim_property') }} p
        on p.listing_id = f.listing_id
       and f.listing_month >= p.valid_from
       and (p.valid_to is null or f.listing_month < p.valid_to)
    group by 1, 2, 3, 4
),

ranked as (
    select
        *,
        rank() over (partition by lga_code order by total_stays desc) as stays_rank
    from listing_type_stays
)

select
    l.lga_name,
    r.property_type,
    r.room_type,
    r.accommodates,
    r.total_stays,
    r.listings,
    round(r.total_stays::numeric / r.listings, 1) as stays_per_listing
from ranked r
join {{ ref('dim_lga') }} l
    on l.lga_code = r.lga_code
   and l.is_current
where r.stays_rank = 1
order by r.total_stays desc
