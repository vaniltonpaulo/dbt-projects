-- Business question: Which stores generate the most revenue?

{{ config(materialized='table') }}

SELECT
    store_name,
    store_city,

    COUNT(*) AS total_sales,
    SUM(units_sold) AS units_sold,
    SUM(retained_revenue) AS total_revenue,

    ROUND(
        SUM(retained_revenue) / NULLIF(COUNT(*), 0),
        2
    ) AS avg_sale_value,

    RANK() OVER (
        ORDER BY SUM(retained_revenue) DESC
    ) AS store_rank

FROM {{ ref('silver_sales_enriched') }}

GROUP BY store_sk, store_name, store_city
ORDER BY store_rank