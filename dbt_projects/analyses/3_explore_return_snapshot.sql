SELECT
    sales_id,
    return_reason,
    dbt_valid_from,
    dbt_valid_to
FROM dbt_dev.snap_returns
WHERE sales_id = 4078
ORDER BY dbt_valid_from;