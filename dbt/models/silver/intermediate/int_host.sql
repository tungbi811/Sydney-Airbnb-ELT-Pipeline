-- Host entity: latest known state of each host (one row per host_id).
-- host_neighbourhood is a suburb; it is mapped to its LGA via the suburb mapping.
-- Blank or unmappable values (e.g. 'Overseas') leave host_neighbourhood_lga NULL.

with latest as (
    select
        host_id,
        host_name,
        host_since,
        host_is_superhost,
        host_neighbourhood,
        scraped_date,
        row_number() over (
            partition by host_id
            order by scraped_date desc, listing_id desc
        ) as rn
    from {{ ref('stg_listings') }}
)

select
    h.host_id,
    h.host_name,
    h.host_since,
    h.host_is_superhost,
    h.host_neighbourhood,
    l.lga_code   as host_neighbourhood_lga_code,
    l.lga_name   as host_neighbourhood_lga,
    h.scraped_date
from latest h
left join {{ ref('stg_suburb_lga_mapping') }} s
    on upper(h.host_neighbourhood) = s.suburb_name
left join {{ ref('stg_lga_codes') }} l
    on s.lga_name = upper(l.lga_name)
where h.rn = 1
