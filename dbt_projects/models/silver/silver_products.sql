{{ config(materialized='view') }}

-- Purpose: Clean product attributes and create price segments for analyzing different product groups.
-- Transformations: Type casting, standardization, and conditional price segmentation. The price bands are example business rules.
WITH products AS (
    SELECT *
    FROM {{ ref('bronze_products') }}
)

SELECT
    product_sk,
    UPPER(TRIM(product_code)) AS product_code,
    TRIM(product_name) AS product_name,
    TRIM(department) AS department,
    TRIM(category) AS category,

    supplier_sk,

    list_price::NUMERIC(14, 2) AS list_price,

    LOWER(TRIM(uom)) AS unit_of_measure,

    CASE
        WHEN list_price IS NULL THEN 'Unknown'
        WHEN list_price < 5 THEN 'Under 5'
        WHEN list_price < 25 THEN '5 to under 25'
        WHEN list_price < 100 THEN '25 to under 100'
        ELSE '100 and above'
    END AS list_price_band

FROM products