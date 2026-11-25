-- Business question: How much revenue does the business generate each day?
-- Grain: one row per sale_date.

SELECT
    sale_date,

    COUNT(*) AS total_sales,
    SUM(units_sold) AS total_units,

    SUM(net_revenue_before_returns) AS revenue,
    SUM(refunded_amount) AS refunds,
    SUM(retained_revenue) AS final_revenue,

    ROUND(SUM(retained_revenue) / COUNT(*), 2) AS avg_sale_value

FROM {{ ref('silver_sales_enriched') }}

GROUP BY sale_date
