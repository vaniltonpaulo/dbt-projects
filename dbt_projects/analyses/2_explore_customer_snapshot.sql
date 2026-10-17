SELECT
    customer_sk,
    email,
    dbt_valid_from,
    dbt_valid_to
FROM dbt_dev.snap_customers
WHERE customer_sk = 1
ORDER BY dbt_valid_from;