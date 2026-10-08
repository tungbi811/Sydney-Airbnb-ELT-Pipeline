-- Suburb entity from host_neighbourhood, mapped to its LGA. One row per suburb seen in
-- the listings. Suburbs without a mapping (e.g. 'Overseas') are kept with a NULL LGA.

with suburbs as (
    select
        upper(host_neighbourhood) as suburb_name,
        max(scraped_date)         as scraped_date
    from {{ ref('stg_listings') }}
    where host_neighbourhood is not null
    group by upper(host_neighbourhood)
)

select
    s.suburb_name,
    l.lga_code,
    l.lga_name,
    s.scraped_date
from suburbs s
left join {{ ref('stg_suburb_lga_mapping') }} m
    on s.suburb_name = m.suburb_name
left join {{ ref('stg_lga_codes') }} l
    on m.lga_name = upper(l.lga_name)
