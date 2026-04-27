-- stg_general_payments.sql
-- Staging model for CMS General Payments 2024
-- Reads from: raw.general_payments_2024
-- Outputs to: staging.stg_general_payments
-- Jobs: rename to snake_case, cast types, trim strings, flag nulls

WITH source AS (
    SELECT * FROM {{ source('raw', 'general_payments_2024') }}
),

renamed AS (
    SELECT

        -- -------------------------
        -- RECORD METADATA
        -- -------------------------
        CAST(Record_ID AS STRING)                           AS record_id,
        Program_Year                                        AS program_year,
        Payment_Publication_Date                            AS payment_publication_date,
        Dispute_Status_for_Publication                      AS dispute_status_for_publication,
        Delay_in_Publication_Indicator                      AS delay_in_publication_indicator,
        TRIM(Change_Type)                                   AS change_type,

        -- Null flag: record_id is the primary key
        (Record_ID IS NULL)                                 AS is_record_id_missing,

        -- -------------------------
        -- PHYSICIAN IDENTITY
        -- -------------------------
        CAST(Covered_Recipient_Profile_ID AS STRING)        AS covered_recipient_profile_id,
        CAST(Covered_Recipient_NPI AS STRING)               AS covered_recipient_npi,
        TRIM(Covered_Recipient_First_Name)                  AS covered_recipient_first_name,
        TRIM(Covered_Recipient_Middle_Name)                 AS covered_recipient_middle_name,
        TRIM(Covered_Recipient_Last_Name)                   AS covered_recipient_last_name,
        TRIM(Covered_Recipient_Name_Suffix)                 AS covered_recipient_name_suffix,
        TRIM(Covered_Recipient_Type)                        AS covered_recipient_type,

        (Covered_Recipient_NPI IS NULL)                     AS is_npi_missing,


        -- -------------------------
        -- PHYSICIAN SPECIALTY & TYPE
        -- -------------------------
        TRIM(Covered_Recipient_Primary_Type_1)              AS covered_recipient_primary_type_1,
        TRIM(Covered_Recipient_Primary_Type_2)              AS covered_recipient_primary_type_2,
        TRIM(Covered_Recipient_Primary_Type_3)              AS covered_recipient_primary_type_3,
        TRIM(Covered_Recipient_Primary_Type_4)              AS covered_recipient_primary_type_4,
        TRIM(Covered_Recipient_Primary_Type_5)              AS covered_recipient_primary_type_5,
        TRIM(Covered_Recipient_Primary_Type_6)              AS covered_recipient_primary_type_6,

        TRIM(Covered_Recipient_Specialty_1)                 AS covered_recipient_specialty_1,
        TRIM(Covered_Recipient_Specialty_2)                 AS covered_recipient_specialty_2,
        TRIM(Covered_Recipient_Specialty_3)                 AS covered_recipient_specialty_3,
        TRIM(Covered_Recipient_Specialty_4)                 AS covered_recipient_specialty_4,
        TRIM(Covered_Recipient_Specialty_5)                 AS covered_recipient_specialty_5,
        TRIM(Covered_Recipient_Specialty_6)                 AS covered_recipient_specialty_6,

        TRIM(Covered_Recipient_License_State_code1)         AS covered_recipient_license_state_code_1,
        TRIM(Covered_Recipient_License_State_code2)         AS covered_recipient_license_state_code_2,
        TRIM(Covered_Recipient_License_State_code3)         AS covered_recipient_license_state_code_3,
        TRIM(Covered_Recipient_License_State_code4)         AS covered_recipient_license_state_code_4,
        TRIM(Covered_Recipient_License_State_code5)         AS covered_recipient_license_state_code_5,

        -- -------------------------
        -- TEACHING HOSPITAL IDENTITY
        -- -------------------------
        CAST(Teaching_Hospital_CCN AS STRING)               AS teaching_hospital_ccn,
        CAST(Teaching_Hospital_ID AS STRING)                AS teaching_hospital_id,
        TRIM(Teaching_Hospital_Name)                        AS teaching_hospital_name,

        (Teaching_Hospital_ID IS NULL)                      AS is_teaching_hospital_id_missing,

        -- -------------------------
        -- RECIPIENT ADDRESS
        -- -------------------------
        TRIM(Recipient_Primary_Business_Street_Address_Line1) AS recipient_primary_business_street_address_line_1,
        TRIM(Recipient_Primary_Business_Street_Address_Line2) AS recipient_primary_business_street_address_line_2,
        TRIM(Recipient_City)                                  AS recipient_city,
        TRIM(Recipient_State)                                 AS recipient_state,
        TRIM(Recipient_Zip_Code)                              AS recipient_zip_code,
        TRIM(Recipient_Country)                               AS recipient_country,
        TRIM(Recipient_Province)                              AS recipient_province,
        TRIM(Recipient_Postal_Code)                           AS recipient_postal_code,

        -- -------------------------
        -- PAYING COMPANY
        -- -------------------------
        TRIM(Submitting_Applicable_Manufacturer_or_Applicable_GPO_Name)             AS submitting_applicable_manufacturer_or_applicable_gpo_name,
        TRIM(Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_Name)         AS applicable_manufacturer_or_applicable_gpo_making_payment_name,
        TRIM(Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_State)        AS applicable_manufacturer_or_applicable_gpo_making_payment_state,
        TRIM(Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_Country)      AS applicable_manufacturer_or_applicable_gpo_making_payment_country,
        CAST(Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_ID AS STRING) AS applicable_manufacturer_or_applicable_gpo_making_payment_id,

        (Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_ID IS NULL)       AS is_manufacturer_payment_id_missing,

        -- -------------------------
        -- PAYMENT DETAILS
        -- -------------------------
        CAST(Total_Amount_of_Payment_USDollars AS NUMERIC)                      AS total_amount_of_payment_us_dollars,
        Date_of_Payment                                                         AS date_of_payment,
        Number_of_Payments_Included_in_Total_Amount                             AS number_of_payments_included_in_total_amount,
        TRIM(Form_of_Payment_or_Transfer_of_Value)                              AS form_of_payment_or_transfer_of_value,
        TRIM(Nature_of_Payment_or_Transfer_of_Value)                            AS nature_of_payment_or_transfer_of_value,
        Physician_Ownership_Indicator                                           AS physician_ownership_indicator,
        Charity_Indicator                                                       AS charity_indicator,
        Related_Product_Indicator                                               AS related_product_indicator,
        TRIM(Third_Party_Payment_Recipient_Indicator)                           AS third_party_payment_recipient_indicator,
        TRIM(Name_of_Third_Party_Entity_Receiving_Payment_or_Transfer_of_Value) AS name_of_third_party_receiving_payment_or_transfer_of_value,
        Third_Party_Equals_Covered_Recipient_Indicator                          AS third_party_equals_covered_recipient_indicator,
        TRIM(Contextual_Information)                                            AS contextual_information,
        TRIM(City_of_Travel)                                                    AS city_of_travel,
        TRIM(State_of_Travel)                                                   AS state_of_travel,
        TRIM(Country_of_Travel)                                                 AS country_of_travel,

        (Total_Amount_of_Payment_USDollars IS NULL)         AS is_total_amount_missing,
        (Nature_of_Payment_or_Transfer_of_Value IS NULL)    AS is_nature_of_payment_missing,

        -- -------------------------
        -- ASSOCIATED PRODUCTS (slots 1–5)
        -- -------------------------
        TRIM(Covered_or_Noncovered_Indicator_1)                         AS covered_or_noncovered_indicator_1,
        TRIM(Covered_or_Noncovered_Indicator_2)                         AS covered_or_noncovered_indicator_2,
        TRIM(Covered_or_Noncovered_Indicator_3)                         AS covered_or_noncovered_indicator_3,
        TRIM(Covered_or_Noncovered_Indicator_4)                         AS covered_or_noncovered_indicator_4,
        TRIM(Covered_or_Noncovered_Indicator_5)                         AS covered_or_noncovered_indicator_5,

        TRIM(Indicate_Drug_or_Biological_or_Device_or_Medical_Supply_1) AS indicate_drug_or_biological_or_device_or_medical_supply_1,
        TRIM(Indicate_Drug_or_Biological_or_Device_or_Medical_Supply_2) AS indicate_drug_or_biological_or_device_or_medical_supply_2,
        TRIM(Indicate_Drug_or_Biological_or_Device_or_Medical_Supply_3) AS indicate_drug_or_biological_or_device_or_medical_supply_3,
        TRIM(Indicate_Drug_or_Biological_or_Device_or_Medical_Supply_4) AS indicate_drug_or_biological_or_device_or_medical_supply_4,
        TRIM(Indicate_Drug_or_Biological_or_Device_or_Medical_Supply_5) AS indicate_drug_or_biological_or_device_or_medical_supply_5,

        TRIM(Product_Category_or_Therapeutic_Area_1)                    AS product_category_or_therapeutic_area_1,
        TRIM(Product_Category_or_Therapeutic_Area_2)                    AS product_category_or_therapeutic_area_2,
        TRIM(Product_Category_or_Therapeutic_Area_3)                    AS product_category_or_therapeutic_area_3,
        TRIM(Product_Category_or_Therapeutic_Area_4)                    AS product_category_or_therapeutic_area_4,
        TRIM(Product_Category_or_Therapeutic_Area_5)                    AS product_category_or_therapeutic_area_5,

        TRIM(Name_of_Drug_or_Biological_or_Device_or_Medical_Supply_1)  AS name_of_drug_or_biological_or_device_or_medical_supply_1,
        TRIM(Name_of_Drug_or_Biological_or_Device_or_Medical_Supply_2)  AS name_of_drug_or_biological_or_device_or_medical_supply_2,
        TRIM(Name_of_Drug_or_Biological_or_Device_or_Medical_Supply_3)  AS name_of_drug_or_biological_or_device_or_medical_supply_3,
        TRIM(Name_of_Drug_or_Biological_or_Device_or_Medical_Supply_4)  AS name_of_drug_or_biological_or_device_or_medical_supply_4,
        TRIM(Name_of_Drug_or_Biological_or_Device_or_Medical_Supply_5)  AS name_of_drug_or_biological_or_device_or_medical_supply_5,

        TRIM(Associated_Drug_or_Biological_NDC_1)                       AS associated_drug_or_biological_ndc_1,
        TRIM(Associated_Drug_or_Biological_NDC_2)                       AS associated_drug_or_biological_ndc_2,
        TRIM(Associated_Drug_or_Biological_NDC_3)                       AS associated_drug_or_biological_ndc_3,
        TRIM(Associated_Drug_or_Biological_NDC_4)                       AS associated_drug_or_biological_ndc_4,
        TRIM(Associated_Drug_or_Biological_NDC_5)                       AS associated_drug_or_biological_ndc_5,

        TRIM(Associated_Device_or_Medical_Supply_PDI_1)                 AS associated_device_or_medical_supply_pdi_1,
        CAST(Associated_Device_or_Medical_Supply_PDI_2 AS STRING)       AS associated_device_or_medical_supply_pdi_2,
        CAST(Associated_Device_or_Medical_Supply_PDI_3 AS STRING)       AS associated_device_or_medical_supply_pdi_3,
        TRIM(Associated_Device_or_Medical_Supply_PDI_4)                 AS associated_device_or_medical_supply_pdi_4,
        TRIM(Associated_Device_or_Medical_Supply_PDI_5)                 AS associated_device_or_medical_supply_pdi_5

    FROM source
)

SELECT * FROM renamed