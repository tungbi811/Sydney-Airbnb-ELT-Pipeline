-- Q(b): is the median age of an LGA (Census) correlated with its estimated revenue per active listing?
-- One row per LGA for a scatter plot; the Pearson correlation is repeated on every row.

with lga_revenue as (
    select
        lga_code,
        sum(estimated_revenue)::numeric
            / count(distinct listing_id) filter (where has_availability) as revenue_per_active_listing
    from {{ ref('fact_listings') }}
    group by lga_code
)

select
    l.lga_name,
    g2.median_age_persons,
    round(r.revenue_per_active_listing, 2)                                               as revenue_per_active_listing,
    round((corr(g2.median_age_persons, r.revenue_per_active_listing) over ())::numeric, 3) as correlation
from lga_revenue r
join {{ ref('dim_lga') }} l
    on l.lga_code = r.lga_code
   and l.is_current
join {{ ref('ref_census_g02') }} g2
    on g2.lga_code = r.lga_code
order by g2.median_age_persons
