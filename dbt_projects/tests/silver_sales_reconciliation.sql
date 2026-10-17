WITH bronze AS (
    SELECT
        COUNT(*) AS row_count,
        SUM(gross_amount)::NUMERIC(18, 2)
            AS gross_revenue,
        SUM(discount_amount)::NUMERIC(18, 2)
            AS discount_amount,
        SUM(net_amount)::NUMERIC(18, 2)
            AS net_revenue
    FROM {{ ref('bronze_sales') }}
),

silver AS (
    SELECT
        COUNT(*) AS row_count,
        SUM(gross_revenue)::NUMERIC(18, 2)
            AS gross_revenue,
        SUM(discount_amount)::NUMERIC(18, 2)
            AS discount_amount,
        SUM(net_revenue_before_returns)::NUMERIC(18, 2)
            AS net_revenue
    FROM {{ ref('silver_sales_enriched') }}
)

SELECT bronze.*, silver.*
FROM bronze
CROSS JOIN silver

WHERE bronze.row_count != silver.row_count
   OR bronze.gross_revenue
      IS DISTINCT FROM silver.gross_revenue
   OR bronze.discount_amount
      IS DISTINCT FROM silver.discount_amount
   OR bronze.net_revenue
      IS DISTINCT FROM silver.net_revenue