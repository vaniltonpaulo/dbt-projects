-- This is the main silver transformation.
-- It combines sales with customers, products, stores, dates, and aggregated returns to produce a complete transactional analytics dataset.


{{ config(materialized='view') }}

WITH sales AS (
    SELECT *
    FROM {{ ref('bronze_sales') }}
),

return_summary AS (
    SELECT
        sales_id,

        COUNT(*) AS return_event_count,

        SUM(returned_qty) AS returned_quantity,

        SUM(refund_amount) AS refunded_amount,

        STRING_AGG(
            DISTINCT return_reason,
            ', ' ORDER BY return_reason
        ) AS return_reasons,

        BOOL_OR(refund_exceeds_sale_net)
            AS has_refund_exceeding_sale_net,

        BOOL_OR(returned_qty_exceeds_sold_qty)
            AS has_return_qty_exceeding_sale_qty

    FROM {{ ref('silver_returns') }}

    GROUP BY sales_id
),

joined AS (
    SELECT
        -- Transaction
        s.sales_id,
        s.date_sk,

        -- Calendar
        d.date::DATE AS sale_date,
        DATE_TRUNC('month', d.date::DATE)::DATE
            AS sale_month,

        d.year AS sale_year,
        d.quarter AS sale_quarter,
        d.month AS sale_month_number,
        d.day_name AS sale_day_name,
        d.is_weekend::BOOLEAN AS is_weekend,

        -- Store
        s.store_sk,
        st.store_code,
        st.store_name,
        st.city AS store_city,
        st.region AS store_region,
        st.country AS store_country,
        st.store_size_band,

        -- Product
        s.product_sk,
        p.product_code,
        p.product_name,
        p.department,
        p.category,
        p.list_price,
        p.list_price_band,

        -- Customer
        s.customer_sk,
        c.customer_code,
        c.loyalty_tier,
        c.is_loyalty_member,
        c.signup_date,

        (
            d.date::DATE - c.signup_date
        ) AS customer_tenure_days_at_sale,

        -- Promotion
        s.promotion_sk,

        (
            s.promotion_sk IS NOT NULL
        ) AS has_promotion,

        s.payment_method,

        -- Sales metrics
        s.quantity::INTEGER AS units_sold,

        s.unit_price::NUMERIC(14, 2)
            AS actual_unit_price,

        s.gross_amount::NUMERIC(14, 2)
            AS gross_revenue,

        s.discount_amount::NUMERIC(14, 2)
            AS discount_amount,

        s.net_amount::NUMERIC(14, 2)
            AS net_revenue_before_returns,

        -- Returns
        COALESCE(
            r.return_event_count, 0
        ) AS return_event_count,

        COALESCE(
            r.returned_quantity, 0
        ) AS returned_quantity,

        COALESCE(
            r.refunded_amount, 0::NUMERIC
        ) AS refunded_amount,

        r.return_reasons,

        COALESCE(
            r.has_refund_exceeding_sale_net,
            FALSE
        ) AS has_refund_exceeding_sale_net,

        COALESCE(
            r.has_return_qty_exceeding_sale_qty,
            FALSE
        ) AS has_return_qty_exceeding_sale_qty

    FROM sales s

    LEFT JOIN {{ ref('bronze_date') }} d
        ON s.date_sk = d.date_sk

    LEFT JOIN {{ ref('silver_stores') }} st
        ON s.store_sk = st.store_sk

    LEFT JOIN {{ ref('silver_products') }} p
        ON s.product_sk = p.product_sk

    LEFT JOIN {{ ref('silver_customers') }} c
        ON s.customer_sk = c.customer_sk

    LEFT JOIN return_summary r
        ON s.sales_id = r.sales_id
)

SELECT
    *,

    -- Return status
    (
        return_event_count > 0
    ) AS has_return,

    -- Units retained
    (
        units_sold - returned_quantity
    ) AS units_retained,

    -- Revenue after refunds
    (
        net_revenue_before_returns - refunded_amount
    )::NUMERIC(14, 2) AS retained_revenue,

    -- Effective discount rate
    CASE
        WHEN gross_revenue > 0
        THEN ROUND(
            discount_amount / gross_revenue,
            4
        )
        ELSE NULL
    END AS effective_discount_rate,

    -- Returned unit rate
    CASE
        WHEN units_sold > 0
        THEN ROUND(
            returned_quantity::NUMERIC / units_sold,
            4
        )
        ELSE NULL
    END AS returned_unit_rate,

    -- Selling price relative to list price
    (
        actual_unit_price - list_price
    )::NUMERIC(14, 2)
        AS unit_price_vs_list_difference,

    -- Flag for unusual total refunds
    (
        refunded_amount > net_revenue_before_returns
    ) AS total_refund_exceeds_sale_net

FROM joined