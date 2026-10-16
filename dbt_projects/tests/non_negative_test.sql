-- If you want to test that the gross_amount and net_amount columns 
-- are non-negative. If you get no rows after running the test passed
-- You have to read as in reverse 
SELECT *
FROM {{ ref('bronze_sales') }}
WHERE gross_amount < 0 AND net_amount < 0 