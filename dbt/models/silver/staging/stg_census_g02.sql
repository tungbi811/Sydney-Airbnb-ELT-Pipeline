-- Census 2016 G02 (Selected Medians and Averages) at LGA level.
-- 'LGA10050' -> 10050 so it joins to stg_lga_codes.

select
    substring(lga_code_2016 from 4)::int        as lga_code,
    median_age_persons::int                     as median_age_persons,
    median_mortgage_repay_monthly::int          as median_mortgage_repay_monthly,
    median_tot_prsnl_inc_weekly::int            as median_tot_prsnl_inc_weekly,
    median_rent_weekly::int                     as median_rent_weekly,
    median_tot_fam_inc_weekly::int              as median_tot_fam_inc_weekly,
    average_num_psns_per_bedroom::numeric       as average_num_psns_per_bedroom,
    median_tot_hhd_inc_weekly::int              as median_tot_hhd_inc_weekly,
    average_household_size::numeric             as average_household_size
from {{ source('bronze', 'census_g02') }}
