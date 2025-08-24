import os
import sys
import time
import logging
import pandas as pd
import pyodbc
from dotenv import load_dotenv

# ---------- logging ----------
os.makedirs("./logs", exist_ok=True)
logging.basicConfig(
    filename=f'./logs/etl_{time.strftime("%Y%m%d_%H%M%S")}.log',
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
log = logging.getLogger("etl")

# ---------- env ----------
load_dotenv()
SERVER   = os.getenv("SQL_SERVER")
DB       = os.getenv("SQL_DATABASE")
UID      = os.getenv("SQL_UID")
PWD      = os.getenv("SQL_PWD")
DRIVER   = os.getenv("ODBC_DRIVER", "ODBC Driver 17 for SQL Server")
CSV_PATH = os.getenv("SOURCE_CSV", "./data/prospects.csv")

if not all([SERVER, DB, UID, PWD, DRIVER]):
    log.error("Missing SQL env vars.")
    sys.exit(1)

if not os.path.exists(CSV_PATH):
    log.error(f"Source file not found: {CSV_PATH}")
    sys.exit(1)

conn_str = f"DRIVER={{{DRIVER}}};SERVER={SERVER};DATABASE={DB};UID={UID};PWD={PWD};TrustServerCertificate=yes;"
log.info("Connecting to SQL Server...")
cn = pyodbc.connect(conn_str, autocommit=False)
cur = cn.cursor()
log.info("Connected.")

# ---------- load & standardize ----------
log.info(f"Reading CSV: {CSV_PATH}")
df = pd.read_csv(CSV_PATH)

# Normalize expected columns
expected = [
    "id_prospect","date_creation","canal",
    "email_valide","sms_valide","cin_uploadee",
    "biometrie_reussie","infos_complementaires",
    "rdv_pris","signature_electronique"
]
# rename common variants (if any)
rename_map = {c.lower(): c for c in expected}
df.columns = [rename_map.get(c.lower(), c) for c in df.columns]

missing = [c for c in expected if c not in df.columns]
if missing:
    log.error(f"Missing columns: {missing}")
    sys.exit(1)

# cast types
df["date_creation"] = pd.to_datetime(df["date_creation"]).dt.date
bool_cols = [c for c in expected if c not in ("id_prospect","date_creation","canal")]
for c in bool_cols:
    df[c] = df[c].astype(int).clip(0,1)

# ---------- stage: truncate + bulk insert ----------
log.info("Truncating staging ...")
cur.execute("TRUNCATE TABLE dbo.stg_prospects_cih;")

log.info("Bulk inserting into staging ...")
insert_sql = """
INSERT INTO dbo.stg_prospects_cih (
    id_prospect, date_creation, canal,
    email_valide, sms_valide, cin_uploadee,
    biometrie_reussie, infos_complementaires, rdv_pris, signature_electronique
) VALUES (?,?,?,?,?,?,?,?,?,?)
"""
cur.fast_executemany = True
cur.executemany(
    insert_sql,
    df[[
        "id_prospect","date_creation","canal",
        "email_valide","sms_valide","cin_uploadee",
        "biometrie_reussie","infos_complementaires","rdv_pris","signature_electronique"
    ]].values.tolist()
)
cn.commit()
rows_staged = len(df)
log.info(f"Staged rows: {rows_staged}")

# ---------- MERGE ----------
log.info("Running MERGE proc ...")
cur.execute("EXEC dbo.sp_merge_prospects_cih;")
cn.commit()
log.info("MERGE done and run logged in etl_run_log.")

# sanity check
cur.execute("SELECT TOP 1 * FROM dbo.prospects_cih;")
_ = cur.fetchone()
log.info("Sanity check OK.")

cur.close()
cn.close()
log.info("ETL finished successfully.")
print("ETL finished successfully.")
