-- Version history of one customer in the SCD2 snapshot.
SELECT
    customer_sk,
    email,
    dbt_valid_from,
    dbt_valid_to
FROM {{ ref('snap_customers') }}
WHERE customer_sk = 1
ORDER BY dbt_valid_from
