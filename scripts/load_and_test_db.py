"""
Automated Database Loader and SQL Test Runner
Loads processed CSVs into a SQLite database and executes all queries in sql/02_analytical_queries.sql.
"""

import sqlite3
import pandas as pd
import os
import re

DB_PATH = "healthcare.db"
CSV_DOCTORS = "data/processed/dim_doctors.csv"
CSV_PATIENTS = "data/processed/dim_patients.csv"
CSV_ADMISSIONS = "data/processed/fact_admissions.csv"
SQL_QUERIES_PATH = "sql/02_analytical_queries.sql"

def setup_database():
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Load Doctors
    print("Loading Dim_Doctors...")
    df_doctors = pd.read_csv(CSV_DOCTORS)
    df_doctors.columns = [c.lower() for c in df_doctors.columns]
    df_doctors.to_sql("doctors", conn, if_exists="replace", index=False)
    
    # Load Patients
    print("Loading Dim_Patients...")
    df_patients = pd.read_csv(CSV_PATIENTS)
    df_patients.columns = [c.lower() for c in df_patients.columns]
    df_patients.to_sql("patients", conn, if_exists="replace", index=False)
    
    # Load Admissions
    print("Loading Fact_Admissions...")
    df_admissions = pd.read_csv(CSV_ADMISSIONS)
    df_admissions.columns = [c.lower() for c in df_admissions.columns]
    df_admissions.to_sql("admissions", conn, if_exists="replace", index=False)
    
    # Check counts
    cursor.execute("SELECT COUNT(*) FROM doctors")
    d_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM patients")
    p_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM admissions")
    a_count = cursor.fetchone()[0]
    
    print(f"Loaded: {d_count} doctors, {p_count} patients, {a_count} admissions.")
    return conn

def test_queries(conn):
    with open(SQL_QUERIES_PATH, "r", encoding="utf-8") as f:
        sql_content = f.read()

    # Split into queries by semicolon
    # Remove single line comments
    clean_lines = []
    for line in sql_content.splitlines():
        if line.strip().startswith("--"):
            clean_lines.append("")
        else:
            clean_lines.append(line)
    
    raw_statements = "\n".join(clean_lines).split(";")
    
    queries = [s.strip() for s in raw_statements if s.strip()]
    print(f"\nFound {len(queries)} analytical queries in {SQL_QUERIES_PATH}.")
    
    cursor = conn.cursor()
    success_count = 0
    for idx, q in enumerate(queries, 1):
        try:
            cursor.execute(q)
            rows = cursor.fetchall()
            col_names = [d[0] for d in cursor.description]
            print(f"✓ Query {idx:02d}: Success ({len(rows)} rows returned, cols: {', '.join(col_names[:3])})")
            success_count += 1
        except Exception as e:
            print(f"✗ Query {idx:02d} FAILED:\nError: {e}\nQuery snippet:\n{q[:150]}...\n")
            raise e

    print(f"\nAll {success_count}/{len(queries)} analytical queries executed successfully!")

if __name__ == "__main__":
    conn = setup_database()
    test_queries(conn)
    conn.close()

