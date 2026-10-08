-- Q(a): demographic differences between the top 3 and bottom 3 LGAs
-- by estimated revenue per active listing over the 12 months (May 2020 - Apr 2021).

with lga_revenue as (
    select
        lga_code,
        -- 12-month revenue divided by the listings that were active at least once
        sum(estimated_revenue)::numeric
            / count(distinct listing_id) filter (where has_availability) as revenue_per_active_listing
    from {{ ref('fact_listings') }}
    group by lga_code
),

ranked as (
    select
        *,
        rank() over (order by revenue_per_active_listing desc) as rank_top,
        rank() over (order by revenue_per_active_listing asc)  as rank_bottom
    from lga_revenue
)

select
    case when r.rank_top <= 3 then 'top 3' else 'bottom 3' end as performance_group,
    l.lga_name,
    round(r.revenue_per_active_listing, 2)                      as revenue_per_active_listing,
    g2.median_age_persons,
    g2.average_household_size,
    g2.median_tot_hhd_inc_weekly,
    -- age distribution as % of the LGA population
    round(100.0 * (g1.age_0_4_yr_p + g1.age_5_14_yr_p) / g1.tot_p_p, 1)                     as pct_age_0_14,
    round(100.0 * (g1.age_15_19_yr_p + g1.age_20_24_yr_p) / g1.tot_p_p, 1)                  as pct_age_15_24,
    round(100.0 * (g1.age_25_34_yr_p + g1.age_35_44_yr_p) / g1.tot_p_p, 1)                  as pct_age_25_44,
    round(100.0 * (g1.age_45_54_yr_p + g1.age_55_64_yr_p) / g1.tot_p_p, 1)                  as pct_age_45_64,
    round(100.0 * (g1.age_65_74_yr_p + g1.age_75_84_yr_p + g1.age_85ov_p) / g1.tot_p_p, 1) as pct_age_65_plus
from ranked r
join {{ ref('dim_lga') }} l
    on l.lga_code = r.lga_code
   and l.is_current
join {{ ref('ref_census_g01') }} g1
    on g1.lga_code = r.lga_code
join {{ ref('ref_census_g02') }} g2
    on g2.lga_code = r.lga_code
where r.rank_top <= 3
   or r.rank_bottom <= 3
order by r.revenue_per_active_listing desc
