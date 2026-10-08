-- Q(e): for hosts with a single listing, does the 12-month estimated revenue cover the
-- annualised median mortgage repayment of the listing's LGA? One row per LGA.

with single_listing_hosts as (
    select host_id
    from {{ ref('fact_listings') }}
    group by host_id
    having count(distinct listing_id) = 1
),

host_revenue as (
    select
        f.host_id,
        -- latest LGA of the listing, in case it changed during the year
        (array_agg(f.lga_code order by f.listing_month desc))[1] as lga_code,
        sum(f.estimated_revenue)                                as revenue_12m
    from {{ ref('fact_listings') }} f
    join single_listing_hosts s
        on s.host_id = f.host_id
    group by f.host_id
)

select
    l.lga_name,
    g2.median_mortgage_repay_monthly * 12                                        as annual_mortgage,
    count(*)                                                                     as single_listing_hosts,
    count(*) filter (where h.revenue_12m >= g2.median_mortgage_repay_monthly * 12) as hosts_covering,
    round(100.0 * count(*) filter (where h.revenue_12m >= g2.median_mortgage_repay_monthly * 12)
          / count(*), 1)                                                         as pct_covering
from host_revenue h
join {{ ref('dim_lga') }} l
    on l.lga_code = h.lga_code
   and l.is_current
join {{ ref('ref_census_g02') }} g2
    on g2.lga_code = h.lga_code
group by l.lga_name, g2.median_mortgage_repay_monthly
order by pct_covering desc
