# Healthcare Analytics Master Data Dictionary

This data dictionary outlines the schema, data types, business definitions, and valid value ranges for the Healthcare Operations Analytics Project.

---

## 1. `admissions` (`Fact_Admissions`)

| Column Name | Data Type | Nullable | Description & Business Rules | Example Values |
| :--- | :--- | :--- | :--- | :--- |
| `encounter_id` | `INT` | No | Primary Key. Unique identifier for each inpatient hospitalization. | `1`, `2`, `3` |
| `patient_id` | `INT` | No | Foreign Key referencing `patients(patient_id)`. | `3490`, `2470` |
| `doctor_id` | `INT` | No | Foreign Key referencing `doctors(doctor_id)`. | `4`, `50` |
| `admission_date` | `DATE` | No | Calendar date of patient intake/admission (`YYYY-MM-DD`). | `2025-11-02` |
| `discharge_date` | `DATE` | No | Calendar date of patient discharge (`YYYY-MM-DD`). Must be $\ge$ `admission_date`. | `2025-11-05` |
| `admission_type` | `VARCHAR(50)` | No | Priority classification of encounter intake. | `Emergency`, `Elective`, `Urgent` |
| `primary_diagnosis` | `VARCHAR(200)` | No | Clinical condition diagnosed at admission. | `Cholecystitis`, `Sepsis`, `Osteoarthritis` |
| `total_charges` | `DECIMAL(12,2)` | No | Gross chargemaster billed amount in USD ($). | `14302.55`, `13085.67` |
| `net_paid` | `DECIMAL(12,2)` | No | Total revenue realized and collected (Payer + Patient). | `13430.21`, `10892.57` |
| `waived_amount` | `DECIMAL(12,2)` | No | Contractual adjustment / uncollected write-off (`total_charges - net_paid`). | `872.34`, `2193.10` |
| `patient_satisfaction` | `INT` | Yes | Post-discharge survey rating on a 1 (Lowest) to 5 (Highest) scale. | `4`, `5`, `NULL` |
| `readmission_30_days` | `VARCHAR(10)` | No | Indicator if patient was readmitted within 30 days post-discharge (`Yes`/`No`). | `Yes`, `No` |
| `year_quarter` | `INT` | No | Fiscal quarter of encounter admission (1 to 4). | `1`, `2`, `3`, `4` |
| `stay_days` | `INT` | No | Duration of inpatient stay in days (`discharge_date - admission_date`). | `3`, `4`, `5` |

---

## 2. `patients` (`Dim_Patients`)

| Column Name | Data Type | Nullable | Description & Business Rules | Example Values |
| :--- | :--- | :--- | :--- | :--- |
| `patient_id` | `INT` | No | Primary Key. Master Patient Index (MPI) identifier. | `1`, `2`, `3500` |
| `patient_name` | `VARCHAR(100)` | No | Full legal name of the patient. | `Robert Miller`, `Michael Smith` |
| `gender` | `VARCHAR(20)` | No | Demographic biological sex category. | `Male`, `Female` |
| `age` | `INT` | No | Patient age at registration in years. Corrupted entries median-imputed. | `35`, `40`, `57` |
| `insurance_provider` | `VARCHAR(200)` | No | Primary health insurance carrier (unallocated populated as `"N/A"`). | `Medicare`, `Blue Cross`, `Self-Pay`, `N/A` |

---

## 3. `doctors` (`Dim_Doctors`)

| Column Name | Data Type | Nullable | Description & Business Rules | Example Values |
| :--- | :--- | :--- | :--- | :--- |
| `doctor_id` | `INT` | No | Primary Key. Unique credentialed provider identifier. | `1`, `2`, `50` |
| `doctor_name` | `VARCHAR(100)` | No | Attending physician's full name. | `Dr. David Martin`, `Dr. Jane Lopez` |
| `specialty` | `VARCHAR(100)` | No | Clinical clinical service line / medical department. | `Neurology`, `General Surgery`, `Orthopedics` |

