-- Property entity: latest known physical attributes of each listing (one row per listing_id).

with latest as (
    select
        listing_id,
        property_type,
        room_type,
        accommodates,
        scraped_date,
        row_number() over (
            partition by listing_id
            order by scraped_date desc
        ) as rn
    from {{ ref('stg_listings') }}
)

select
    listing_id,
    property_type,
    room_type,
    accommodates,
    scraped_date
from latest
where rn = 1
