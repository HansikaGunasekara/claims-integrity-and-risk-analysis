-- ________________________________
-- Slide 2: Age Demographic Analysis
-- ________________________________
-- What is the distribution of patients in different birth decades?
SELECT 
  CASE
    WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1950 AND 1959 THEN '1950s'
    WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1960 AND 1969 THEN '1960s'
    WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1970 AND 1979 THEN '1970s'
    WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1980 AND 1989 THEN '1980s'
    WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1990 AND 1999 THEN '1990s'
    ELSE '2000s'
  END AS birth_decade,
 count(patient_id) number_of_patients
FROM zeta-flare-473308-d3.hospital_management.patients
GROUP BY birth_decade
ORDER BY birth_decade;
-- birth_decade	number_of_patients
-- 1950s	6
-- 1960s	8
-- 1970s	9
-- 1980s	8
-- 1990s	13
-- 2000s	6

-- ________________________________
-- Slide 3: Demographic Insights
-- ________________________________
-- What are the claim frequencies for paid bills in different birth decades?
SELECT 
      CASE
        WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1950 AND 1959 THEN '1950s'
        WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1960 AND 1969 THEN '1960s'
        WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1970 AND 1979 THEN '1970s'
        WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1980 AND 1989 THEN '1980s'
        WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1990 AND 1999 THEN '1990s'
        ELSE '2000s'
      END AS birth_decade,
      count(patients.patient_id) number_of_patients
FROM zeta-flare-473308-d3.hospital_management.billing billing
LEFT JOIN zeta-flare-473308-d3.hospital_management.patients patients
  ON billing.patient_id = patients.patient_id
GROUP BY birth_decade, billing.payment_method, billing.payment_status
HAVING billing.payment_method = 'Insurance' AND billing.payment_status IN ('Paid')
ORDER BY birth_decade;

-- What are the claim frequencies for failed bills in different birth decades?
SELECT 
      CASE
        WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1950 AND 1959 THEN '1950s'
        WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1960 AND 1969 THEN '1960s'
        WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1970 AND 1979 THEN '1970s'
        WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1980 AND 1989 THEN '1980s'
        WHEN EXTRACT(YEAR from date_of_birth) BETWEEN 1990 AND 1999 THEN '1990s'
        ELSE '2000s'
      END AS birth_decade,
      count(patients.patient_id) number_of_patients
FROM zeta-flare-473308-d3.hospital_management.billing billing
LEFT JOIN zeta-flare-473308-d3.hospital_management.patients patients
  ON billing.patient_id = patients.patient_id
GROUP BY birth_decade, billing.payment_method, billing.payment_status
HAVING billing.payment_method = 'Insurance' AND billing.payment_status IN ('Failed')
ORDER BY birth_decade;

-- ________________________________
-- Slide 4: Payout Efficiency
-- ________________________________
-- What is the overall payment efficiency in the billing department?
SELECT ROUND(SAFE_DIVIDE(SUM(CASE WHEN payment_status = 'Paid' THEN 1 ELSE 0 END),
                          COUNT(bill_id))*100, 2) Payout_Efficiency
FROM zeta-flare-473308-d3.hospital_management.billing;
-- Overall payment efficiency = 32%

-- What are the payment situations for the bills which were submitted to the insurance
SELECT payment_status, COUNT(bill_id) Number_of_bills
FROM zeta-flare-473308-d3.hospital_management.billing
WHERE payment_method = 'Insurance'
GROUP BY payment_status;

-- ________________________________
-- Slide 5: Claim Fail Rate Measures
-- ________________________________
-- Find the number of policies per insurance provider
SELECT Insurance_Provider, COUNT(patient_id) Number_of_Patients
FROM zeta-flare-473308-d3.hospital_management.patients
GROUP BY insurance_provider;

-- insurance_provider	number_of_patients
-- MedCare Plus	18
-- WellnessCorp	16
-- PulseSecure	10
-- HealthIndia	6

-- Get the fail rates for insurance providers
SELECT p.insurance_provider Insurance_Provider,
        ROUND(SAFE_DIVIDE(
          SUM(CASE WHEN b.payment_status = 'Failed' THEN 1 ELSE 0 END),
          COUNT(b.bill_id))*100, 1) Fail_Rate
FROM zeta-flare-473308-d3.hospital_management.billing b
LEFT JOIN zeta-flare-473308-d3.hospital_management.patients p
ON b.patient_id = p.patient_id
WHERE b.payment_method = 'Insurance'
GROUP BY p.insurance_provider;

-- insurance_provider	fail_rate
-- PulseSecure	16.7
-- MedCare Plus	30.3
-- WellnessCorp	42.9
-- HealthIndia	60.0

-- ________________________________
-- Slide 6: Verify claim bills for Cancel/No-show Appointments
-- ________________________________
-- Find the number of No-show/Cancelled Appointments
SELECT COUNT(appointment_id) Number_of_NoShows_Cancellations
FROM zeta-flare-473308-d3.hospital_management.appointments
WHERE status IN ('No-show', 'Cancelled');

-- Subquery Challenge
-- Show billing data from the billing table for the appointments which were `No-show` or `Cancelled`
-- Inner Query
-- Get the appointment ids for the No-show appointments
SELECT appointment_id
FROM zeta-flare-473308-d3.hospital_management.appointments
WHERE status IN ('No-show', 'Cancelled');

-- Outer Query
SELECT billing.bill_id, billing.payment_status, billing.payment_method, billing.amount
FROM zeta-flare-473308-d3.hospital_management.billing billing
INNER JOIN zeta-flare-473308-d3.hospital_management.treatments treatments
 ON billing.treatment_id = treatments.treatment_id
WHERE treatments.appointment_id in (SELECT appointment_id
                          FROM zeta-flare-473308-d3.hospital_management.appointments
                          WHERE status IN ('No-show', 'Cancelled'));

-- ________________________________
-- Slide 7: Fraud Detection 
-- ________________________________
-- Find the number of paid bills for the No-shows/Cancellations grouped on payment method
SELECT payment_method, COUNT(bill_id) Number_of_bills_paid
FROM zeta-flare-473308-d3.hospital_management.billing billing
INNER JOIN zeta-flare-473308-d3.hospital_management.treatments treatments
 ON billing.treatment_id = treatments.treatment_id
WHERE appointment_id in (SELECT appointment_id
                          FROM zeta-flare-473308-d3.hospital_management.appointments
                          WHERE status IN ('No-show', 'Cancelled'))
GROUP BY payment_method, payment_status
HAVING payment_status = 'Paid';

-- ________________________________
-- Slide 10: Gender Demographic Analysis
-- ________________________________
-- Find the gender distribution for the patients
SELECT gender, COUNT(patient_id) AS number_of_patients
FROM zeta-flare-473308-d3.hospital_management.patients
GROUP BY gender;
-- gender	number_of_patients
-- F	19
-- M	31

-- Find the gender distribution over billings
SELECT patients.gender, COUNT(billing.bill_id) number_of_bills
FROM zeta-flare-473308-d3.hospital_management.billing billing
LEFT JOIN zeta-flare-473308-d3.hospital_management.patients patients
  ON billing.patient_id = patients.patient_id
GROUP BY patients.gender;
-- gender	number_of_bills
-- F	70
-- M	130