-- Business question: Which stores generate the most revenue?
-- Grain: one row per store_sk.

SELECT
    store_sk,
    store_name,
    store_city,

    COUNT(*) AS total_sales,
    SUM(units_sold) AS units_sold,
    SUM(retained_revenue) AS total_revenue,

    ROUND(SUM(retained_revenue) / COUNT(*), 2) AS avg_sale_value,

    RANK() OVER (
        ORDER BY SUM(retained_revenue) DESC
    ) AS store_rank

FROM {{ ref('silver_sales_enriched') }}

GROUP BY store_sk, store_name, store_city
