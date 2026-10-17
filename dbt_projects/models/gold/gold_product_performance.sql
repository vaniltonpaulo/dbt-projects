-- Business question: Which products sell the most, and which have the highest returns?

{{ config(materialized='table') }}

SELECT
    product_name,
    category,

    SUM(units_sold) AS total_units_sold,
    SUM(returned_quantity) AS total_units_returned,

    SUM(retained_revenue) AS total_revenue,

    ROUND(
        SUM(returned_quantity)::NUMERIC
        / NULLIF(SUM(units_sold), 0) * 100,
        2
    ) AS return_rate_pct

FROM {{ ref('silver_sales_enriched') }}

GROUP BY product_sk, product_name, category
ORDER BY total_revenue DESC