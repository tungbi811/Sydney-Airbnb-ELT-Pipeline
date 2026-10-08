-- Suburb -> LGA mapping. Source is UPPERCASE; kept uppercase and matched with
-- upper() in intermediate models (initcap() would break names like 'Ku-ring-gai').

select
    upper(trim(suburb_name)) as suburb_name,
    upper(trim(lga_name))    as lga_name
from {{ source('bronze', 'suburb_lga_mapping') }}
