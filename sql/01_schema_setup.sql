-- =====================================================================
-- Healthcare Operations Analytics Project
-- Database Schema & Ingestion Setup Script
-- Target Database: MySQL / PostgreSQL / SQLite compatible
-- =====================================================================

CREATE DATABASE IF NOT EXISTS healthcare_project;
USE healthcare_project;

-- ---------------------------------------------------------------------
-- 1. Dimension Table: Doctors
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS admissions;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS patients;

CREATE TABLE doctors (
    doctor_id INT PRIMARY KEY,
    doctor_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(100) NOT NULL
);

-- ---------------------------------------------------------------------
-- 2. Dimension Table: Patients
-- ---------------------------------------------------------------------
CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    patient_name VARCHAR(100) NOT NULL,
    gender VARCHAR(20) NOT NULL,
    age INT NOT NULL,
    insurance_provider VARCHAR(200) DEFAULT 'N/A'
);

-- ---------------------------------------------------------------------
-- 3. Fact Table: Inpatient Admissions
-- ---------------------------------------------------------------------
CREATE TABLE admissions (
    encounter_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    admission_date DATE NOT NULL,
    discharge_date DATE NOT NULL,
    admission_type VARCHAR(50) NOT NULL,
    primary_diagnosis VARCHAR(200) NOT NULL,
    total_charges DECIMAL(12, 2) NOT NULL,
    net_paid DECIMAL(12, 2) NOT NULL,
    waived_amount DECIMAL(12, 2) NOT NULL,
    patient_satisfaction INT,
    readmission_30_days VARCHAR(10) NOT NULL,
    year_quarter INT NOT NULL,
    stay_days INT NOT NULL,
    
    -- Integrity Constraints
    CONSTRAINT chk_satisfaction CHECK (patient_satisfaction BETWEEN 1 AND 5 OR patient_satisfaction IS NULL),
    CONSTRAINT chk_year_quarter CHECK (year_quarter BETWEEN 1 AND 4),
    CONSTRAINT chk_discharge_date CHECK (discharge_date >= admission_date),
    CONSTRAINT chk_readmission CHECK (readmission_30_days IN ('Yes', 'No')),
    
    -- Relational Integrity
    CONSTRAINT fk_admissions_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    CONSTRAINT fk_admissions_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);

-- ---------------------------------------------------------------------
-- 4. Bulk Ingestion (MySQL LOAD DATA INFILE Template)
-- Note: Replace file paths with your absolute path or use the provided
-- automated Python loader script (scripts/load_and_test_db.py).
-- ---------------------------------------------------------------------

/*
LOAD DATA LOCAL INFILE 'data/processed/dim_doctors.csv'
INTO TABLE doctors
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'data/processed/dim_patients.csv'
INTO TABLE patients
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'data/processed/fact_admissions.csv'
INTO TABLE admissions
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
*/

