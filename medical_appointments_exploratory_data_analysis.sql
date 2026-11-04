/*
PROJECT: Healthcare Analytics - Medical Appointment No-Show Analysis
PART 2: Data Exploration

DESCRIPTION:
Exploring the cleaned medical appointment dataset to identify patterns and
factors associated with missed healthcare appointments. This analysis examines
no-show rates across appointment timing, patient demographics, SMS reminders,
and neighborhoods. It also uses patient appointment history to develop a
basic risk-scoring approach for identifying appointments that may be more
likely to be missed.

OBJECTIVES:
1. Calculate the overall appointment no-show rate.
2. Examine no-show rates by day of the week.
3. Analyze the relationship between appointment lead time and no-shows.
4. Compare no-show rates across different age groups.
5. Examine no-show rates for patients who received SMS reminders.
6. Identify neighborhoods with higher appointment no-show rates.
7. Use window functions to examine patients' previous appointment history.
8. Create a view that categorizes appointments into risk tiers based on previous no-shows 
and appointment lead time.
*/


-- QUESTION 1: What's our overall no-show rate?
-- Calculates the total number of appointments and percentage of no-show appointments 
	
SELECT no_show,
COUNT(*) AS total_appointments,
ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM medical_appointments_staging), 2) AS pct_of_total
FROM medical_appointments_staging
GROUP BY no_show;
    
    
-- QUESTION 2: Does the day of the week matter?
-- Groups appointments by the day of the week to compare no-show rates
-- DAYNAME() returns the weekday name from the appointment date.
-- CASE WHEN counts appointments marked as no-shows.

SELECT DAYNAME(AppointmentDay) AS appointment_day,
	COUNT(*) AS total_appointments,
	SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS no_shows,
	ROUND (SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS rate_of_no_shows
FROM medical_appointments_staging
GROUP BY DAYNAME(AppointmentDay)
ORDER BY rate_of_no_shows DESC;


-- QUESTION 3: Does lead time matter?

-- Groups appointments based on the number of days between scheduling and the actual appointment date
-- to compare no-show rates across lead-time categories

-- Same day (0 days)
-- Short lead time (1-3 days)
-- Within a week (4-7 days)
-- Long lead time (8+ days)

-- CASE is used to assign each appointment to a lead-time category

SELECT 
	CASE
		WHEN lead_time_days = 0 THEN 'Same Day'
		WHEN lead_time_days BETWEEN 1 AND 3 THEN 'Short (1-3 days)'
        WHEN lead_time_days BETWEEN 4 AND 7 THEN 'Within a week'
        ELSE 'Long Lead (8+ Days)'
	END AS lead_time_bucket,
	COUNT(*) AS total_appointments,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS no_show_rate
FROM medical_appointments_staging
GROUP BY lead_time_bucket
ORDER BY no_show_rate DESC;


-- QUESTION 4: Do age groups matter?

-- Categorizes partients into age groups to compare appointment no-show rates

-- Child (0-12)
-- Teen (13-19)
-- Young adult (20-39)
-- Adult (40-59)
-- Senior (60+)

-- CASE assigns each patient to an age group based on their age.

SELECT 
	CASE
		WHEN Age BETWEEN 0 AND 12 THEN 'Child'
        WHEN Age BETWEEN 13 AND 19 THEN 'Teen'
        WHEN Age BETWEEN 20 AND 39 THEN 'Young Adult'
        WHEN Age BETWEEN 40 AND 59 THEN 'Adult'
        ELSE 'Senior'
	END AS age_group,
    COUNT(*) AS total_appointments,
	 ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS no_show_rate
FROM medical_appointments_staging
GROUP BY age_group
ORDER BY no_show_rate DESC;


-- QUESTION 5: Do SMS reminders help?

-- Compares appointment no-show rates between patients who received an SMS reminder and who didn't
-- CASE is used to label each appointment based on SMS receipt.

SELECT 
	CASE WHEN sms_received = 1 THEN 'Receivied SMS' ELSE 'No SMS'
    END AS sms_status,
	  COUNT(*) AS total_appointments,
	 ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS no_show_rate
FROM medical_appointments_staging
GROUP BY sms_status;


-- QUESTION 6: Which neighborhoods have the highest no-show risk?

-- Calculates no-show rates by neighborhood and ranks neighborhoods from highest to lowest rate.
-- RANK() assigns a ranking based on the no-show rate.
-- HAVING filters out neighborhoods with <100 appointments to avoid ranking areas with very small appointment totals.

SELECT 
	Neighbourhood,
    COUNT(*) AS total_appointments,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS no_show_rate,
    RANK() OVER (ORDER BY ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) DESC)
    AS risk_rank
FROM medical_appointments_staging
GROUP BY Neighbourhood
HAVING COUNT(*) >= 100 
ORDER BY no_show_rate DESC
LIMIT 15;


-- PATIENT-LEVEL RISK SCORING

-- Examines each patient's appointment history to determine how many previous appointments they had and how many of those were no-shows.

-- COUNT() OVER() counts previous appointments for each patient.
-- SUM() OVER() counts previous no-shows for each patient.
-- PARTITION BY separates the calculations by patient.
-- ORDER BY organizes each patient's appointments chronologically.
-- The window frame ends at 1 PRECEDING so the current appointment is excluded from the historical counts.

SELECT patientid, appointmentid, appointmentday, no_show,
	COUNT(*) OVER (
		PARTITION BY PatientID
        ORDER BY AppointmentDay
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prior_appointments,
	SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) OVER 
		(PARTITION BY PatientID
        ORDER BY AppointmentDay
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prior_no_shows
FROM medical_appointments_staging
ORDER BY patientid, AppointmentDay;


-- RISK SCORING VIEW

-- Creates a view that combines appointment details with each patient's previous appointment history to assign a risk tier
-- The CTE (patient_history) calculates the number of previous appointments and previous no-shows for each patient using window functions

-- The final SELECT calculates each patient's historical no-show rate and assigns a risk tier based on previous no-shows and appointment lead time

-- Risk categories:
-- New Patient - Monitor: No previous appointments
-- High Risk: Previous no-show rate of 50% or higher, or lead time of 8+ days
-- Medium Risk: Previous no-show rate of 20% or higher, or lead time of 4-7 days
-- Low Risk: Does not meet the conditions for the other categories

CREATE VIEW v_appointment_risk AS
WITH patient_history AS (
	SELECT
		PatientId,
        AppointmentID,
        AppointmentDay,
        Neighbourhood,
        lead_time_days,
        sms_received,
        Scholarship,
        no_show,
        COUNT(*) OVER (
			PARTITION BY PatientID
            ORDER BY AppointmentDay
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prior_appointments,
		SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) OVER (
			PARTITiON BY PatientID
            ORDER BY AppointmentDay
			ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prior_no_shows
	FROM medical_appointments_staging)
SELECT 
	PatientId,
    AppointmentID,
    AppointmentDay,
    Neighbourhood,
    lead_time_days,
    prior_appointments,
    prior_no_shows,
    ROUND(prior_no_shows / NULLIF(prior_appointments, 0), 2) AS prior_no_show_rate,
    CASE
		WHEN prior_appointments = 0 THEN 'New Patient - Monitor'
        WHEN (prior_no_shows / NULLIF(prior_appointments, 0)) >= 0.5
			OR lead_time_days >= 8 THEN 'High Risk'
		WHEN (prior_no_shows / NULLIF(prior_appointments, 0)) >= 0.2
			OR lead_time_days BETWEEN 4 AND 7 THEN 'Medium Risk'
		ELSE 'Low Risk'
	END AS risk_tier
FROM patient_history;


-- Review appointments categorized as high risk.
-- Displays appointment details and risk information for the first 50 high-risk appointments

SELECT *
FROM v_appointment_risk
WHERE risk_tier = 'High Risk'
ORDER BY AppointmentDay
LIMIT 50;
