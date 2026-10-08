-- Cleaned listings: one row per listing per monthly file.
-- Bronze stores everything as TEXT; here we cast types, normalise blanks to NULL
-- and fix scraped_date values that fall outside the month of their source file.

with source as (
    select * from {{ source('bronze', 'listings') }}
),

typed as (
    select
        listing_id::bigint                                              as listing_id,
        host_id::bigint                                                 as host_id,
        scraped_date::date                                              as scraped_date_raw,
        -- 'listings/07_2020.csv' -> 2020-07-01
        to_date(substring(source_file from '(\d{2}_\d{4})'), 'MM_YYYY') as file_month,

        nullif(trim(host_name), '')                                     as host_name,
        to_date(nullif(trim(host_since), ''), 'DD/MM/YYYY')             as host_since,
        case host_is_superhost when 't' then true when 'f' then false end as host_is_superhost,
        nullif(trim(host_neighbourhood), '')                            as host_neighbourhood,

        trim(listing_neighbourhood)                                     as listing_neighbourhood,
        trim(property_type)                                             as property_type,
        trim(room_type)                                                 as room_type,
        accommodates::int                                               as accommodates,

        price::numeric                                                  as price,
        case has_availability when 't' then true when 'f' then false end as has_availability,
        availability_30::int                                            as availability_30,
        number_of_reviews::int                                          as number_of_reviews,
        nullif(review_scores_rating, '')::numeric                       as review_scores_rating,
        nullif(review_scores_accuracy, '')::numeric                     as review_scores_accuracy,
        nullif(review_scores_cleanliness, '')::numeric                  as review_scores_cleanliness,
        nullif(review_scores_checkin, '')::numeric                      as review_scores_checkin,
        nullif(review_scores_communication, '')::numeric                as review_scores_communication,
        nullif(review_scores_value, '')::numeric                        as review_scores_value,

        source_file
        -- scrape_id dropped: constant value (20200000000000) across all rows
    from source
)

select
    listing_id,
    host_id,
    -- e.g. 4,780 rows in 07_2020.csv are dated 2020-09-05; move them back to the file's month
    case
        when date_trunc('month', scraped_date_raw) = file_month then scraped_date_raw
        else file_month
    end                                                    as scraped_date,
    file_month                                             as listing_month,
    date_trunc('month', scraped_date_raw) <> file_month    as is_scraped_date_corrected,
    host_name,
    host_since,
    host_is_superhost,
    host_neighbourhood,
    listing_neighbourhood,
    property_type,
    room_type,
    accommodates,
    price,
    has_availability,
    availability_30,
    number_of_reviews,
    review_scores_rating,
    review_scores_accuracy,
    review_scores_cleanliness,
    review_scores_checkin,
    review_scores_communication,
    review_scores_value,
    source_file
from typed
