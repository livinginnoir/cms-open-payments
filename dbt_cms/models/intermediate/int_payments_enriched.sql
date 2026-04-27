-- int_payments_enriched.sql
-- Intermediate model for CMS General Payments 2024
-- Reads from: staging.stg_general_payments
-- Outputs to: staging.int_payments_enriched
-- Jobs: standardize company name, derive primary specialty, simplify recipient type

WITH payments AS (
    SELECT * FROM {{ ref('stg_general_payments') }}
),

enriched AS (
    SELECT

        -- -------------------------
        -- PASS-THROUGH KEY FIELDS
        -- -------------------------
        record_id, date_of_payment, program_year,
        total_amount_of_payment_us_dollars,
        nature_of_payment_or_transfer_of_value,
        recipient_state, covered_recipient_npi,
        covered_recipient_profile_id,
        is_record_id_missing, is_npi_missing,
        is_teaching_hospital_id_missing, 
        is_manufacturer_payment_id_missing,
        is_total_amount_missing, is_nature_of_payment_missing,

        -- -------------------------
        -- STANDARDIZED COMPANY NAME
        -- -------------------------
        -- Raw name has casing variance: "Pfizer Inc." vs "PFIZER INC" vs "pfizer"
        -- UPPER + TRIM gives us a consistent grouping key for the marts
        UPPER(TRIM(applicable_manufacturer_or_applicable_gpo_making_payment_name))
                                                AS company_name_standardized,

        -- Keep original for reference
        applicable_manufacturer_or_applicable_gpo_making_payment_name
                                                AS company_name_raw,


        -- -------------------------
        -- PRIMARY SPECIALTY
        -- -------------------------
        -- Use COALESCE across all 6 specialty fields to derive a single primary_specialty column
        COALESCE(covered_recipient_specialty_1, covered_recipient_specialty_2,
            covered_recipient_specialty_3, covered_recipient_specialty_4,
            covered_recipient_specialty_5, covered_recipient_specialty_6)
                                                AS single_primary_specialty,

        -- -------------------------
        -- SIMPLIFIED RECIPIENT TYPE
        -- -------------------------
        CASE
            WHEN covered_recipient_type = 'Covered Recipient Physician' THEN 'Physician'
            WHEN covered_recipient_type = 'Covered Recipient Teaching Hospital' THEN 'Teaching Hospital'
            ELSE 'Other'
        END AS recipient_type
    FROM payments
)

SELECT * FROM enriched