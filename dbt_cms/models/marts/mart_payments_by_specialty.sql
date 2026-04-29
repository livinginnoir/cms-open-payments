-- mart_payments_by_specialty.sql
-- Mart: total and average payments by physician specialty
-- Reads from: int_payments_enriched
-- Outputs: one row per specialty with total payments and avg payments per physician

WITH base_payments AS (

    SELECT
        SPLIT(single_primary_specialty, '|')[SAFE_OFFSET(1)] AS specialty_clean,
        covered_recipient_npi,
        total_amount_of_payment_us_dollars

    FROM {{ ref('int_payments_enriched') }}

    WHERE
        SPLIT(single_primary_specialty, '|')[SAFE_OFFSET(1)] IS NOT NULL
        AND SPLIT(single_primary_specialty, '|')[SAFE_OFFSET(1)] != ''
        AND NOT is_npi_missing
        AND NOT is_total_amount_missing
        AND recipient_type = 'Physician'

),

physician_totals AS (

    SELECT
        specialty_clean,
        covered_recipient_npi,
        SUM(total_amount_of_payment_us_dollars) AS physician_total_payment
    FROM base_payments
    GROUP BY covered_recipient_npi, specialty_clean
    

),

specialty_summary AS (

    -- ⚠️ YOUR BLOCK 3: Aggregate to one row per specialty
    -- You need:
    --   (a) total payments across all physicians in the specialty
    --   (b) count of distinct physicians in the specialty
    --   (c) average total payments per physician
    SELECT
        specialty_clean,
        SUM(physician_total_payment)        AS total_payment_amount,
        COUNT(covered_recipient_npi)        AS physician_count,
        AVG(physician_total_payment)        AS avg_payment_per_physician
    FROM physician_totals
    GROUP BY specialty_clean

)

SELECT
    specialty_clean,
    total_payment_amount,
    physician_count,
    avg_payment_per_physician
FROM specialty_summary
WHERE specialty_clean IS NOT NULL
    AND specialty_clean != ''
ORDER BY total_payment_amount DESC