-- Business question: How much revenue does the business generate each day?
 -- I keep forgeting what this actually does function: NULLIF() prevents division by zero.
{{ config(materialized='table') }}

SELECT
    sale_date,

    COUNT(*) AS total_sales,
    SUM(units_sold) AS total_units,

    SUM(net_revenue_before_returns) AS revenue,
    SUM(refunded_amount) AS refunds,
    SUM(retained_revenue) AS final_revenue,

    ROUND(
        SUM(retained_revenue) / NULLIF(COUNT(*), 0),
        2
    ) AS avg_sale_value

FROM {{ ref('silver_sales_enriched') }}

GROUP BY sale_date
ORDER BY sale_date