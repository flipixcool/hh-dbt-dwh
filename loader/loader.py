import psycopg2
from psycopg2.extras import execute_values
from dotenv import load_dotenv
import pandas as pd
import os

load_dotenv()

conn = psycopg2.connect(
    host=os.getenv("POSTGRES_HOST"),
    port=os.getenv("POSTGRES_PORT"),
    dbname=os.getenv("POSTGRES_DB"),
    user=os.getenv("POSTGRES_USER"),
    password=os.getenv("POSTGRES_PASSWORD")
)


data = pd.read_csv('data/raw/IT_vacancies_full.csv')

cur = conn.cursor()
cur.execute('CREATE SCHEMA IF NOT EXISTS raw')
cur.execute('CREATE TABLE IF NOT EXISTS raw.vacancies ("Ids" INTEGER, "Employer" TEXT, "Name" TEXT, "Salary" BOOLEAN, "From" FLOAT, "To" FLOAT, "Experience" TEXT, "Schedule" TEXT, "Keys" TEXT, "Description" TEXT, "Area" TEXT, "Professional roles" TEXT, "Specializations" TEXT, "Profarea names" TEXT, "Published at" TIMESTAMP);')

cur.execute("SELECT COUNT(*) FROM raw.vacancies")
count = cur.fetchone()[0]

rows = list(data.itertuples(index=False, name=None))
if count == 0:
    execute_values(cur, "INSERT INTO raw.vacancies VALUES %s", rows)
    print(f"Inserted {len(rows)} rows")
else:
    print(f"Table already has {count} rows, skipping insert")




conn.commit()
conn.close()
