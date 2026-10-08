-- Census 2016 G01 reference data (static, no SCD). Joins to dim_lga on lga_code.

select * from {{ ref('stg_census_g01') }}
