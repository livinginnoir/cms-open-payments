# Loads the raw CMS General Payments CSV into BigQuery raw dataset

from google.cloud import bigquery
import os

# --- CONFIG ---
PROJECT_ID = "project-4f698b69-289f-483f-b87"
DATASET_ID = "raw"
TABLE_ID = "general_payments_2024"
CSV_PATH = os.path.expanduser("~/cms-data/raw/OP_DTL_GNRL_PGYR2024_P01232026_01102026.csv")

# --- CONNECT ---
# Create a BigQuery client
client = bigquery.Client()

# --- DEFINE DESTINATION ---
# Build a full table reference string: "project.dataset.table"
table_ref = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"

# --- CONFIGURE THE LOAD JOB ---
job_config = bigquery.LoadJobConfig(
    autodetect=True,
    ignore_unknown_values=True,
    max_bad_records=100000,
    source_format=bigquery.SourceFormat.CSV,
    skip_leading_rows=1,   #skip the header row
    write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,   #overwrite cleanly
)

# --- RUN THE LOAD JOB ---
# Open the CSV file and pass it to client.load_table_from_file()
print(f"Loading {CSV_PATH} into {table_ref}...")
with open(CSV_PATH, "rb") as source_file:
    job = client.load_table_from_file(source_file, table_ref, job_config=job_config)

job.result()

# -- CONFIRM --
# Use the client.get_table(table_ref) to fetch the loaded table
# Print the number of rows using .num_rows
table = client.get_table(table_ref)

print(f"Done. {table.num_rows} rows loaded into {table_ref}.")