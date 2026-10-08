-- LGA code <-> LGA name lookup (e.g. 10050, 'Albury').

select
    trim(lga_code)::int as lga_code,
    trim(lga_name)      as lga_name
from {{ source('bronze', 'lga_codes') }}
