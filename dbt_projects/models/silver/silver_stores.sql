{{ config(materialized='view') }}

-- Purpose: Prepare geographic information and classify stores based on their physical size.
-- Transformations: Geographic standardization, date conversion, and store-size segmentation.
WITH stores AS (
    SELECT *
    FROM {{ ref('bronze_store') }}
)

SELECT
    store_sk,

    UPPER(TRIM(store_code)) AS store_code,
    TRIM(store_name) AS store_name,

    TRIM(city) AS city,
    TRIM(state_province) AS state_province,
    TRIM(region) AS region,
    TRIM(country) AS country,

    open_date::DATE AS open_date,
    sq_ft::INTEGER AS square_feet,

    CASE
        WHEN sq_ft IS NULL THEN 'Unknown'
        WHEN sq_ft < 10000 THEN 'Small'
        WHEN sq_ft < 12000 THEN 'Medium'
        ELSE 'Large'
    END AS store_size_band

FROM stores