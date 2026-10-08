-- Census 2016 G01 (Selected Person Characteristics by Sex) at LGA level.
-- 'LGA10050' -> 10050 so it joins to stg_lga_codes; all count columns cast to int.

{%- set cols = adapter.get_columns_in_relation(source('bronze', 'census_g01')) %}

select
    substring(lga_code_2016 from 4)::int as lga_code,
    {%- for col in cols if col.name != 'lga_code_2016' %}
        {{ col.name }}::int as {{ col.name }}{{ "," if not loop.last }}
    {%- endfor %}
from {{ source('bronze', 'census_g01') }}
