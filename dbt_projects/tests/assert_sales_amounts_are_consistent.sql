-- Every sale must satisfy: gross = quantity * unit_price and net = gross - discount.
-- Returns the offending rows (a 1-cent tolerance absorbs rounding).
SELECT
    sales_id,
    quantity,
    unit_price,
    gross_amount,
    discount_amount,
    net_amount
FROM {{ ref('bronze_sales') }}
WHERE ABS(gross_amount - quantity * unit_price) > 0.01
   OR ABS(net_amount - (gross_amount - discount_amount)) > 0.01
