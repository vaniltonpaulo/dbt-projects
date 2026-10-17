WITH returns AS (
    SELECT
        SUM(refund_amount)::NUMERIC(18, 2)
            AS refunds,
        SUM(returned_qty)::BIGINT AS units
    FROM {{ ref('bronze_returns') }}
),

sales AS (
    SELECT
        SUM(refunded_amount)::NUMERIC(18, 2)
            AS refunds,
        SUM(returned_quantity)::BIGINT AS units
    FROM {{ ref('silver_sales_enriched') }}
)

SELECT returns.*, sales.*
FROM returns
CROSS JOIN sales

WHERE returns.refunds IS DISTINCT FROM sales.refunds
   OR returns.units IS DISTINCT FROM sales.units