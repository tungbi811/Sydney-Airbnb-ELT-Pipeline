-- Census 2016 G02 reference data (static, no SCD). Joins to dim_lga on lga_code.

select * from {{ ref('stg_census_g02') }}
