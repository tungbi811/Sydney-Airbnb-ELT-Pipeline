-- LGA entity from listing_neighbourhood (which is already an LGA name), enriched with its
-- LGA code so it can join to the census tables. One row per LGA seen in the listings.

with neighbourhoods as (
    select
        listing_neighbourhood,
        max(scraped_date) as scraped_date
    from {{ ref('stg_listings') }}
    group by listing_neighbourhood
)

select
    l.lga_code,
    l.lga_name,
    n.scraped_date
from neighbourhoods n
join {{ ref('stg_lga_codes') }} l
    on upper(n.listing_neighbourhood) = upper(l.lga_name)
