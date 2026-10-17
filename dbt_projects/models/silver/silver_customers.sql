{{ config(materialized='view') }}

-- Purpose: Standardize customer information, extract email domains, classify loyalty membership, 
-- and prepare customer dimensions for analysis.

-- Transformations: String cleaning, null handling, email extraction, loyalty categorization, and Boolean flags.
WITH customers AS (
    SELECT *
    FROM {{ ref('bronze_customers') }}
)

SELECT
    customer_sk,
    UPPER(TRIM(customer_code)) AS customer_code,

    NULLIF(TRIM(first_name), '') AS first_name,
    NULLIF(TRIM(last_name), '') AS last_name,

    CONCAT_WS(
        ' ',
        NULLIF(TRIM(first_name), ''),
        NULLIF(TRIM(last_name), '')
    ) AS customer_full_name,

    COALESCE(
        NULLIF(TRIM(gender), ''),
        'Unknown'
    ) AS gender,

    LOWER(NULLIF(TRIM(email), '')) AS email,

    CASE
        WHEN POSITION('@' IN COALESCE(email, '')) > 0
        THEN LOWER(SPLIT_PART(TRIM(email), '@', 2))
        ELSE NULL
    END AS email_domain,

    CASE
        WHEN NULLIF(TRIM(loyalty_tier), '') IS NULL
            THEN 'Unassigned'
        ELSE INITCAP(LOWER(TRIM(loyalty_tier)))
    END AS loyalty_tier,

    (
        NULLIF(TRIM(loyalty_tier), '') IS NOT NULL
    ) AS is_loyalty_member,

    signup_date::DATE AS signup_date

FROM customers