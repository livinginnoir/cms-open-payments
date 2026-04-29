-- mart_payments_by_company.sql
-- Mart: top 20 companies by total payments
-- Reads from: int_payments_enriched
-- Outputs: one row per company with payment totals, nature breakdown, and YoY % change

WITH base_payments AS (

    SELECT
        company_name_standardized,
        program_year,
        total_amount_of_payment_us_dollars,
        nature_of_payment_or_transfer_of_value

    FROM {{ ref('int_payments_enriched') }}

    WHERE
        NOT is_manufacturer_payment_id_missing
        AND NOT is_total_amount_missing
        AND NOT is_nature_of_payment_missing

),

company_totals AS (

    SELECT

        company_name_standardized,
        program_year,
        SUM(total_amount_of_payment_us_dollars) AS total_payment_amount,
        SUM(CASE WHEN nature_of_payment_or_transfer_of_value IN ( 
            'Compensation for services other than consulting, including serving as faculty or as a speaker at a venue other than a continuing education program',
            'Compensation for serving as faculty or as a speaker for a medical education program',
            'Honoraria'
        ) THEN total_amount_of_payment_us_dollars ELSE 0 END) AS total_speaking_fees,
        SUM(CASE WHEN nature_of_payment_or_transfer_of_value = 'Consulting Fee'
            THEN total_amount_of_payment_us_dollars ELSE 0 END) AS total_consulting,
        SUM(CASE WHEN nature_of_payment_or_transfer_of_value = 'Food and Beverage'
            THEN total_amount_of_payment_us_dollars ELSE 0 END) AS total_meals,
        SUM(CASE WHEN nature_of_payment_or_transfer_of_value = 'Grant'
            THEN total_amount_of_payment_us_dollars ELSE 0 END) AS total_research,
        SUM(CASE WHEN nature_of_payment_or_transfer_of_value IN (
            'Acquisitions', 'Charitable Contribution', 'Debt forgiveness', 'Education',
            'Entertainment', 'Gift', 'Long term medical supply or device loan', 
            'Royalty or License', 'Space rental or facility fees (teaching hospital only)',
            'Travel and Lodging'
        ) THEN total_amount_of_payment_us_dollars ELSE 0 END) AS total_other
    FROM base_payments
    GROUP BY
        company_name_standardized,
        program_year

),

yoy_calc AS (

    SELECT
        *,
        ROUND(
            SAFE_DIVIDE(
                total_payment_amount - LAG(total_payment_amount) OVER (
                    PARTITION BY company_name_standardized
                    ORDER BY program_year
                ),
                LAG(total_payment_amount) OVER (
                    PARTITION BY company_name_standardized
                    ORDER BY program_year
                )
            ) * 100,
        2) AS yoy_pct_change_total
    FROM company_totals
),

-- Rank companies by their most recent year's total, then keep top 20
top_companies AS (

    SELECT company_name_standardized
    FROM yoy_calc
    WHERE program_year = (SELECT MAX(program_year) FROM yoy_calc)
    ORDER BY total_payment_amount DESC
    LIMIT 20

)

SELECT
    yoy.*
FROM yoy_calc AS yoy
INNER JOIN top_companies AS tc
    USING (company_name_standardized)
ORDER BY
    yoy.total_payment_amount DESC,
    yoy.program_year DESC

-- YoY will be NULL for the earliest program year for every company since no comparison is available