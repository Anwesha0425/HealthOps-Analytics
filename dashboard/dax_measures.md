# Power BI DAX Formulas & Data Modeling Documentation

This document outlines the calculated columns, data modeling relationships, and dynamic DAX measures engineered in the Power BI dashboard (`Healthcare_Project_Dashboard.pbix`).

---

## 1. Relational Star Schema Architecture

The data model follows an industry-standard **Star Schema** with 1-to-Many (`1:*`) single-direction relationships:

* **`Fact_Admissions` [Patient_ID]** `* -> 1` **`Dim_Patients` [Patient_ID]**
* **`Fact_Admissions` [Doctor_ID]** `* -> 1` **`Dim_Doctors` [Doctor_ID]**

---

## 2. Calculated Columns

### **Satisfaction_Breakdown**
Categorizes raw 1–5 patient satisfaction scores into business-tracking bands:
```dax
Satisfaction_Breakdown = 
SWITCH(
    TRUE(),
    Fact_Admissions[Patient_Satisfaction] >= 4, "High Satisfaction (4-5)",
    Fact_Admissions[Patient_Satisfaction] == 3, "Neutral (3)",
    Fact_Admissions[Patient_Satisfaction] <= 2, "Low Satisfaction (1-2)",
    "Unrated"
)
```

---

## 3. Core KPI Measures

### **Total Gross Charges**
```dax
Total Gross Charges = SUM(Fact_Admissions[Total_Charges])
```

### **Net Realized Collections**
```dax
Net Realized Revenue = SUM(Fact_Admissions[Net_Paid])
```

### **Total Waived / Contractual Write-offs**
```dax
Total Waived Revenue = SUM(Fact_Admissions[Waived_Amount])
```

### **Net Revenue Conversion Rate (%)**
Evaluates revenue realization efficiency by tracking collected dollars against total chargemaster billed amounts:
```dax
Net_Conversion_Rate = 
DIVIDE(
    SUM(Fact_Admissions[Net_Paid]),
    SUM(Fact_Admissions[Total_Charges]),
    0
)
```

### **Total Inpatient Encounters**
```dax
Total Admissions = COUNTROWS(Fact_Admissions)
```

### **Total Unique Patients**
```dax
Total Patients = DISTINCTCOUNT(Dim_Patients[Patient_ID])
```

### **Active Admitted Patients**
```dax
Active Inpatient Patients = DISTINCTCOUNT(Fact_Admissions[Patient_ID])
```

### **Zero-Collection / 100% Waived Encounters**
Isolates the exact volume of admissions where zero dollars were collected:
```dax
Total Fully Waived Encounters = 
CALCULATE(
    COUNTROWS(Fact_Admissions),
    Fact_Admissions[Net_Paid] = 0
)
```

---

## 4. Operational & Velocity Measures

### **Daily Admission Flux (Incoming Velocity)**
Standardized baseline incoming patient rate across annual operating calendar:
```dax
Avg. Daily Admissions = 
DIVIDE(
    COUNTROWS(Fact_Admissions),
    DISTINCTCOUNT(Fact_Admissions[Admission_Date]),
    0
)
```

### **Daily Discharge Velocity (Outward Throughput)**
Measures outward patient turnover capacity:
```dax
Avg. Daily Discharges = 
DIVIDE(
    COUNTROWS(Fact_Admissions),
    DISTINCTCOUNT(Fact_Admissions[Discharge_Date]),
    0
)
```

---

## 5. Clinical Quality & Value-Based Care Measures

### **Average Length of Stay (ALOS)**
Calculates the mean duration of inpatient hospitalizations:
```dax
ALOS = AVERAGE(Fact_Admissions[Stay_Days])
```

### **Total 30-Day Readmissions**
Identifies encounters flagged for unscheduled return within 30 days of prior discharge:
```dax
Total Readmitted Cases = 
CALCULATE(
    COUNTROWS(Fact_Admissions),
    LOWER(Fact_Admissions[Readmission_30_Days]) = "yes"
)
```

### **30-Day Readmission Exposure Rate (%)**
Tracks facility-wide readmission percentage to monitor CMS Hospital Readmissions Reduction Program (HRRP) penalty risk:
```dax
Readmission % 30 Days = 
DIVIDE(
    [Total Readmitted Cases],
    COUNTROWS(Fact_Admissions),
    0
)
```

### **Average Patient Satisfaction Score**
```dax
Avg Patient Satisfaction = 
AVERAGE(Fact_Admissions[Patient_Satisfaction])
```

