/*
PROJECT: Healthcare Analytics - Medical Appointment No-Show Analysis
PART 1: Data Cleaning

DESCRIPTION:
Cleaning and preparing a medical appointment dataset for analysis to investigate factors 
associated with missed healthcare appointments.

OBJECTIVES:
1. Identify and address data quality issues.
2. Standardize column names, data types, and date formats.
3. Identify and handle invalid or inconsistent values.
4. Create additional columns to support further analysis.
5. Prepare a cleaned dataset for exploratory data analysis.
*/

-- Preview original dataset

SELECT *
FROM medical_appointments
LIMIT 10;


-- Create a staging table with same column structure as the original dataset

CREATE TABLE medical_appointments_staging
LIKE medical_appointments;


-- Copy the original dataset into the staging table to keep original data unchanged during cleaning

INSERT medical_appointments_staging
SELECT *
FROM medical_appointments;


-- Preview the staging table to verify data was copied

SELECT *
FROM medical_appointments_staging
LIMIT 10;


-- Rename columns to correct spelling errors and improve readability

ALTER TABLE medical_appointments_staging
	CHANGE COLUMN Hipertension hypertension INT,
    CHANGE COLUMN Handcap disability_count INT,
    CHANGE COLUMN `No-show` no_show VARCHAR(3);
    
    
-- Review appointment date columns before modifying 
    
SELECT ScheduledDay, AppointmentDay
FROM medical_appointments_staging
LIMIT 10;
    
    
-- Add temporary columns to store cleaned date values
    
ALTER TABLE medical_appointments_staging
	ADD COLUMN ScheduledDay_clean DATETIME,
    ADD COLUMN AppointmentDay_clean DATE;


-- Convert the date strings into standardized date formats
-- REPLACE() removes the 'T' and 'Z'
-- STR_TO_DATE() converts the resulting strings into MySQL date values

UPDATE medical_appointments_staging
SET ScheduledDay_clean = STR_TO_DATE(REPLACE(REPLACE(
ScheduledDay, 'T', ' '), 'Z', ' '), '%Y-%m-%d %H:%i:%s'),
	AppointmentDay_clean = STR_TO_DATE(REPLACE(REPLACE(
AppointmentDay, 'T', ' '), 'Z', ' '), '%Y-%m-%d %H:%i:%s');


-- Remove the orignal uncleaned date columns

ALTER TABLE medical_appointments_staging
	DROP COLUMN ScheduledDay,
    DROP COLUMN AppointmentDay;


-- Rename the cleaned date columns to the original column names

ALTER TABLE medical_appointments_staging
	CHANGE COLUMN ScheduledDay_clean ScheduledDay DATETIME,
    CHANGE COLUMN AppointmentDay_clean AppointmentDay DATE;
    
    
-- Review the cleaned date columns to verify date conversions
    
SELECT ScheduledDay, AppointmentDay
FROM medical_appointments_staging
LIMIT 10;

-- Check the minimum and maximum ages to identify invalid or unusual values

SELECT MIN(age), MAX(age)
FROM medical_appointments_staging;


-- Remove records containing an invalid age value of -1

DELETE FROM medical_appointments_staging
WHERE AGE = -1;


-- Add a new column to calculate the number of days between scheduling date and actual appointment date

ALTER TABLE medical_appointments_staging
ADD COLUMN lead_time_days INT;


-- Calculate the lead time in days for each appointment
-- DATEDIFF() calculates the difference between the scheduling date and actual appointment date

UPDATE medical_appointments_staging
SET lead_time_days = DATEDIFF(AppointmentDay, DATE(ScheduledDay));


-- Check the min and max lead times to identify unusually long or short scheduling intervals

SELECT MIN(lead_time_days), MAX(lead_time_days)
FROM medical_appointments_staging;


-- Identify appointments with negative lead times (records with actual appointment date earlier than the scheduled date)

SELECT *
FROM medical_appointments_staging
WHERE lead_time_days < 0;


-- Remove records with negative lead times, they represent invalid scheduling intervals

DELETE FROM medical_appointments_staging
WHERE lead_time_days < 0;


-- Review the cleaned dataset (limited to 50 rows)

SELECT *
FROM medical_appointments_staging
LIMIT 50;


