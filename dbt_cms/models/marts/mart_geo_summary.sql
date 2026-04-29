-- mart_geo_summary.sql
-- Mart: payments by state with top 5 cities per state
-- Reads from: int_payments_enriched
-- Outputs: one row per state+city combination, state total repeated

WITH base_payments AS (

    SELECT
        recipient_state,
        recipient_city,
        total_amount_of_payment_us_dollars

    FROM {{ ref('int_payments_enriched') }}

    WHERE
        recipient_state IS NOT NULL
        AND recipient_state != ''
        AND recipient_city IS NOT NULL
        AND recipient_city != ''
        AND NOT is_total_amount_missing
        AND NOT is_npi_missing

),

state_totals AS (

    SELECT
        recipient_state,
        SUM(total_amount_of_payment_us_dollars) AS state_total_payment
        FROM base_payments
        GROUP BY recipient_state

),

city_totals AS (

    SELECT
        recipient_state,
        recipient_city,
        SUM(total_amount_of_payment_us_dollars) AS city_total_payment,
        ROW_NUMBER() OVER (
            PARTITION BY recipient_state
            ORDER BY SUM(total_amount_of_payment_us_dollars) DESC
        ) AS city_rank
    FROM base_payments
    GROUP BY recipient_state, recipient_city
)

SELECT
    s.recipient_state,
    s.state_total_payment,
    c.recipient_city,
    c.city_total_payment,
    c.city_rank
FROM state_totals AS s
INNER JOIN city_totals AS c
    USING (recipient_state)
WHERE c.city_rank <= 5
ORDER BY
    s.state_total_payment DESC,
    c.city_rank ASC