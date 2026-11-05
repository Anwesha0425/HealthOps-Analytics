-- =====================================================================
-- Healthcare Operations Analytics Project
-- Production Analytical Queries
-- =====================================================================

-- ---------------------------------------------------------------------
-- SECTION 1: REVENUE CYCLE MANAGEMENT & FINANCIAL PERFORMANCE
-- ---------------------------------------------------------------------

-- Q1. Total Portfolio Revenue Summary (Gross, Net Realized, and Waived)
SELECT 
    ROUND(SUM(total_charges), 2) AS gross_revenue,
    ROUND(SUM(net_paid), 2) AS net_revenue,
    ROUND(SUM(waived_amount), 2) AS waived_revenue,
    ROUND(SUM(net_paid) * 100.0 / SUM(total_charges), 2) AS net_conversion_rate_pct
FROM admissions;

-- Q2. Outlier and Boundary Analysis (Min/Max Billing Metrics)
SELECT 
    MIN(total_charges) AS min_bill,
    MAX(total_charges) AS max_bill,
    MIN(net_paid) AS min_paid_amount,
    MAX(net_paid) AS max_paid_amount,
    MIN(waived_amount) AS min_waived_amount,
    MAX(waived_amount) AS max_waived_amount
FROM admissions;

-- Q3. Average Charge & Payment Per Encounter
SELECT 
    ROUND(AVG(total_charges), 2) AS avg_bill,
    ROUND(AVG(net_paid), 2) AS avg_paid_amount,
    ROUND(AVG(waived_amount), 2) AS avg_waived_amount
FROM admissions;

-- Q4. Department-Wise Total Revenue & Financial Leakage
SELECT 
    d.specialty AS department,
    ROUND(SUM(a.total_charges), 2) AS gross_revenue,
    ROUND(SUM(a.net_paid), 2) AS net_revenue,
    ROUND(SUM(a.waived_amount), 2) AS waived_revenue,
    ROUND(SUM(a.net_paid) * 100.0 / SUM(a.total_charges), 2) AS realization_rate_pct
FROM doctors d
LEFT JOIN admissions a ON d.doctor_id = a.doctor_id
GROUP BY d.specialty
ORDER BY gross_revenue DESC;

-- Q5. Department-Wise Average Charge & Collection Metrics
SELECT 
    d.specialty AS department,
    ROUND(AVG(a.total_charges), 2) AS avg_bill,
    ROUND(AVG(a.net_paid), 2) AS avg_paid_amount,
    ROUND(AVG(a.waived_amount), 2) AS avg_waived_amount
FROM doctors d
LEFT JOIN admissions a ON d.doctor_id = a.doctor_id
GROUP BY d.specialty
ORDER BY avg_bill DESC;

-- Q6. Payer Performance & Unallocated Revenue Leakage Analysis
SELECT 
    COALESCE(NULLIF(p.insurance_provider, ''), 'N/A') AS insurance_provider,
    COUNT(DISTINCT p.patient_id) AS unique_patients,
    COUNT(a.encounter_id) AS total_admissions,
    ROUND(SUM(a.total_charges), 2) AS gross_revenue,
    ROUND(SUM(a.net_paid), 2) AS net_revenue,
    ROUND(SUM(a.waived_amount), 2) AS waived_revenue,
    ROUND(SUM(a.net_paid) * 100.0 / NULLIF(SUM(a.total_charges), 0), 2) AS net_realization_rate_pct
FROM patients p
LEFT JOIN admissions a ON p.patient_id = a.patient_id
GROUP BY COALESCE(NULLIF(p.insurance_provider, ''), 'N/A')
ORDER BY gross_revenue DESC;


-- ---------------------------------------------------------------------
-- SECTION 2: PATIENT DEMOGRAPHICS & CAPACITY UTILIZATION
-- ---------------------------------------------------------------------

-- Q7. Total Patient Population Baseline in Master Index
SELECT 
    COUNT(patient_id) AS total_registered_patients
FROM patients;

-- Q8. Net Inpatient Encounter Patients vs. Non-Admitted Outpatients
SELECT 
    COUNT(DISTINCT a.patient_id) AS active_inpatient_patients,
    (SELECT COUNT(p.patient_id) 
     FROM patients p 
     LEFT JOIN admissions a ON p.patient_id = a.patient_id 
     WHERE a.patient_id IS NULL) AS registered_non_admitted_patients
FROM admissions a;

-- Q9. Visit Frequency Distribution & Patient Satisfaction Correlation
SELECT 
    visit_count,
    COUNT(patient_id) AS patient_count,
    ROUND(AVG(patient_satisfaction), 2) AS avg_satisfaction_rating
FROM (
    SELECT 
        patient_id,
        COUNT(encounter_id) AS visit_count,
        AVG(patient_satisfaction) AS patient_satisfaction
    FROM admissions
    GROUP BY patient_id
) sub
GROUP BY visit_count
ORDER BY patient_count DESC;

-- Q10. Comprehensive Age Demographic Distribution (Including Pediatric Cohort)
SELECT 
    COUNT(CASE WHEN p.age < 18 THEN 1 END) AS pediatric_under_18,
    COUNT(CASE WHEN p.age BETWEEN 18 AND 35 THEN 1 END) AS young_adult_18_to_35,
    COUNT(CASE WHEN p.age BETWEEN 36 AND 65 THEN 1 END) AS middle_aged_36_to_65,
    COUNT(CASE WHEN p.age > 65 THEN 1 END) AS senior_citizen_over_65
FROM patients p
INNER JOIN admissions a ON p.patient_id = a.patient_id;


-- ---------------------------------------------------------------------
-- SECTION 3: PROVIDER PRODUCTIVITY & CLINICAL WORKLOAD
-- ---------------------------------------------------------------------

-- Q11. Department Workload, Admissions Volume & Average Satisfaction
SELECT 
    d.specialty AS department,
    COUNT(a.encounter_id) AS total_admissions,
    ROUND(AVG(a.patient_satisfaction), 2) AS avg_satisfaction_rating
FROM doctors d
LEFT JOIN admissions a ON d.doctor_id = a.doctor_id
GROUP BY d.specialty
ORDER BY total_admissions DESC;

-- Q12. Medical Staff Headcount & Patient-to-Doctor Staffing Ratio
SELECT 
    d.specialty AS department,
    COUNT(DISTINCT d.doctor_id) AS num_of_doctors,
    COUNT(a.encounter_id) AS total_encounters,
    ROUND(COUNT(a.encounter_id) * 1.0 / NULLIF(COUNT(DISTINCT d.doctor_id), 0), 1) AS patients_per_doctor
FROM doctors d
LEFT JOIN admissions a ON d.doctor_id = a.doctor_id
GROUP BY d.specialty
ORDER BY num_of_doctors DESC;

-- Q13. Top-Performing Doctor per Clinical Department (Dense Ranking by Volume & Quality)
WITH provider_rankings AS (
    SELECT 
        d.doctor_id,
        d.doctor_name,
        d.specialty AS department,
        COUNT(a.encounter_id) AS patient_count,
        ROUND(AVG(a.patient_satisfaction), 2) AS avg_satisfaction_rating,
        DENSE_RANK() OVER (
            PARTITION BY d.specialty 
            ORDER BY COUNT(a.encounter_id) DESC, AVG(a.patient_satisfaction) DESC
        ) AS ranking
    FROM doctors d
    INNER JOIN admissions a ON d.doctor_id = a.doctor_id
    GROUP BY d.doctor_id, d.doctor_name, d.specialty
)
SELECT 
    doctor_id,
    doctor_name,
    department,
    patient_count,
    avg_satisfaction_rating
FROM provider_rankings
WHERE ranking = 1
ORDER BY patient_count DESC;


-- ---------------------------------------------------------------------
-- SECTION 4: CLINICAL QUALITY & 30-DAY READMISSION EXPOSURES
-- ---------------------------------------------------------------------

-- Q14. Facility Overall 30-Day Readmission Exposure Rate
SELECT 
    ROUND(COUNT(CASE WHEN LOWER(readmission_30_days) = 'yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS facility_30_day_readmission_pct
FROM admissions;

-- Q15. Readmission Rate by Primary Clinical Diagnosis
SELECT 
    primary_diagnosis,
    COUNT(encounter_id) AS total_cases,
    COUNT(CASE WHEN LOWER(readmission_30_days) = 'yes' THEN 1 END) AS readmitted_cases,
    ROUND(COUNT(CASE WHEN LOWER(readmission_30_days) = 'yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS readmission_rate_pct
FROM admissions
GROUP BY primary_diagnosis
ORDER BY readmission_rate_pct DESC;

-- Q16. Average Length of Stay (ALOS) by Diagnosis
SELECT 
    primary_diagnosis,
    COUNT(encounter_id) AS total_cases,
    ROUND(AVG(stay_days), 2) AS avg_stay_days
FROM admissions
GROUP BY primary_diagnosis
ORDER BY avg_stay_days DESC;

-- Q17. Top 3 and Bottom 3 Doctors by 30-Day Readmission Rate
WITH provider_readmission AS (
    SELECT 
        d.doctor_id,
        d.doctor_name,
        d.specialty,
        COUNT(a.encounter_id) AS total_cases,
        ROUND(COUNT(CASE WHEN LOWER(a.readmission_30_days) = 'yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS readmission_rate_pct,
        ROW_NUMBER() OVER (ORDER BY COUNT(CASE WHEN LOWER(a.readmission_30_days) = 'yes' THEN 1 END) * 100.0 / COUNT(*) DESC) AS rnk_highest,
        ROW_NUMBER() OVER (ORDER BY COUNT(CASE WHEN LOWER(a.readmission_30_days) = 'yes' THEN 1 END) * 100.0 / COUNT(*) ASC) AS rnk_lowest
    FROM doctors d
    INNER JOIN admissions a ON d.doctor_id = a.doctor_id
    GROUP BY d.doctor_id, d.doctor_name, d.specialty
    HAVING COUNT(a.encounter_id) >= 20  -- Credibility threshold: minimum 20 admissions
)
SELECT 'Highest Readmission Risk' AS cohort, doctor_id, doctor_name, specialty, total_cases, readmission_rate_pct
FROM provider_readmission WHERE rnk_highest <= 3
UNION ALL
SELECT 'Lowest Readmission Risk' AS cohort, doctor_id, doctor_name, specialty, total_cases, readmission_rate_pct
FROM provider_readmission WHERE rnk_lowest <= 3;

-- Q18. Correlation Analysis: Stay Duration (ALOS) vs. Readmission Rate & Satisfaction
SELECT 
    stay_days,
    COUNT(encounter_id) AS total_cases,
    ROUND(COUNT(CASE WHEN LOWER(readmission_30_days) = 'yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS readmission_rate_pct,
    ROUND(AVG(patient_satisfaction), 2) AS avg_satisfaction_rating
FROM admissions
GROUP BY stay_days
ORDER BY stay_days;

