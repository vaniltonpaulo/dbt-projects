{{ config(materialized='view') }}

-- Purpose: Enrich return records with their original sales and detect potential data-quality problems.
-- This is useful because refund amounts should be interpreted in the context of the original transaction.

 -- Transformations:
-- - Joins return records to original sales.
-- - Calculates percentage of purchased units returned.
-- - Identifies orphan returns (returns without matching sales).
-- - Flags refunds greater than the original net sale amount.
-- - Flags returned quantities greater than sold quantities.
-- - Detects inconsistent product/store references.


WITH returns AS (
    SELECT *
    FROM {{ ref('bronze_returns') }}
),

sales AS (
    SELECT
        sales_id,
        quantity,
        net_amount,
        product_sk,
        store_sk
    FROM {{ ref('bronze_sales') }}
),

dates AS (
    SELECT
        date_sk,
        date
    FROM {{ ref('bronze_date') }}
)

SELECT
    r.sales_id,
    r.date_sk AS return_date_sk,
    d.date::DATE AS return_date,

    r.store_sk,
    r.product_sk,

    r.returned_qty::INTEGER AS returned_qty,

    COALESCE(
        NULLIF(TRIM(r.return_reason), ''),
        'Unknown'
    ) AS return_reason,

    r.refund_amount::NUMERIC(14, 2) AS refund_amount,

    s.quantity AS original_sale_quantity,
    s.net_amount::NUMERIC(14, 2)
        AS original_sale_net_amount,

    CASE
        WHEN s.quantity > 0
        THEN ROUND(
            r.returned_qty::NUMERIC / s.quantity,
            4
        )
        ELSE NULL
    END AS returned_quantity_share,

    (s.sales_id IS NULL) AS is_orphan_return,

    (
        s.sales_id IS NOT NULL
        AND (
            r.product_sk IS DISTINCT FROM s.product_sk
            OR r.store_sk IS DISTINCT FROM s.store_sk
        )
    ) AS has_dimension_mismatch,

    (
        s.sales_id IS NOT NULL
        AND r.refund_amount > s.net_amount
    ) AS refund_exceeds_sale_net,

    (
        s.sales_id IS NOT NULL
        AND r.returned_qty > s.quantity
    ) AS returned_qty_exceeds_sold_qty

FROM returns r

LEFT JOIN sales s
    ON r.sales_id = s.sales_id

LEFT JOIN dates d
    ON r.date_sk = d.date_sk