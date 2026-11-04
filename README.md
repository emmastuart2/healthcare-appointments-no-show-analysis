# Healthcare Analytics – Medical Appointments No-Show Analysis

## Project Overview

This project explores a medical appointment dataset to identify patterns associated with missed appointments (no-shows). Using **MySQL**, I cleaned and analyzed the data to examine how appointment timing, patient demographics, SMS reminders, and neighborhood relate to no-show rates.

I also used SQL window functions to analyze patient appointment history and created a rule-based appointment risk classification. Finally, I built an interactive dashboard in **Tableau Public** to present key findings.

## Tools & Technologies

- **MySQL:** Data cleaning, exploratory data analysis, aggregations, CTEs, window functions, and views
- **Tableau Public:** Interactive dashboard and data visualization
- **Excel / CSV:** Dataset storage and preparation

## Project Objectives

- Clean and prepare the medical appointment dataset for analysis.
- Calculate the overall appointment no-show rate.
- Examine no-show patterns across appointment days, lead times, age groups, SMS reminders, and neighborhoods.
- Analyze patient appointment history using SQL window functions.
- Develop a rule-based appointment risk classification.
- Build an interactive Tableau dashboard to communicate key findings.

## Business Questions

The exploratory data analysis focused on answering the following questions:

1. What is the overall appointment no-show rate?
2. Does the day of the week matter?
3. Does appointment lead time matter?
4. Do age groups matter?
5. Do SMS reminders help?
6. Which neighborhoods have the highest no-show rates?

## Additional Analysis

Beyond the initial exploratory analysis, I also:

- **Analyzed Patient Appointment History:** Used SQL window functions to calculate each patient's previous appointment count and number of previous no-shows.
- **Developed an Appointment Risk Classification:** Created a SQL view (`v_appointment_risk`) using patient appointment history and lead time to categorize appointments into Low, Medium, High, and New Patient - Monitor risk tiers.

## Key Findings

- **Overall No-Show Rate:** Approximately 20.19% of appointments resulted in a no-show.
- **Day of the Week:** Saturday had the highest no-show rate at 23.08%, but only had 39 appointments. Thursday had the lowest rate at 19.35%, across 17,246 appointments.
- **Appointment Lead Time:** Appointments scheduled 8 or more days in advance had a 32.06% no-show rate. Same-day appointments had a much lower rate of 4.65%.
- **Age Groups:** Teenagers had the highest no-show rate at 25.95%, while seniors had the lowest at 15.31%. Overall, no-show rates decreased as age increased across the age categories.
- **SMS Reminders:** Appointments where patients received an SMS reminder had a 27.57% no-show rate, compared to 16.70% for appointments without a reminder. This is an observed association, not evidence that reminders increase no-shows. SMS reminders may be sent more often for appointments with longer lead times, which are also associated with higher no-show rates.
- **Neighborhoods:** Santos Dumont had the highest no-show rate at 28.92% among the neighborhoods included in the analysis. The SQL query only included neighborhoods with at least 100 appointments.

## Project Files

### Data
- `medical_appointments_raw.csv` – Original dataset.
- `medical_appointments_cleaned.csv` – Cleaned dataset used for analysis.
- `medical_appointments_risk_analysis.csv` – Data used for the appointment risk analysis.

### SQL
- `medical_appointments_data_cleaning.sql` – SQL script for cleaning and preparing the dataset.
- `medical_appointments_exploratory_data_analysis.sql` – SQL queries for exploratory analysis, patient history, and risk classification.

### Tableau
- `appointment_no_show_dashboard.twbx` – Packaged Tableau workbook.
- `dashboard_screenshot.png` – Screenshot of the completed dashboard.

## SQL Analysis

The SQL analysis was completed in two parts:

1. **Data Cleaning:** Created a staging table, standardized column names, converted date fields, removed invalid age values, calculated appointment lead times, and removed records with negative lead times.
2. **Exploratory Data Analysis:** Used aggregate functions, conditional logic, CTEs, window functions, and a SQL view to examine no-show patterns and develop appointment risk categories.

## Tableau Dashboard

The interactive dashboard presents the main findings from the analysis, including overall no-show rates and comparisons across appointment days, lead times, age groups, SMS reminders, and neighborhoods.

[View Interactive Tableau Dashboard](https://public.tableau.com/app/profile/emma.stuart8163/viz/MedicalAppointmentsNo-ShowDashboard/AppointmentNo-ShowDashboard)

![Healthcare Appointment No-Show Dashboard](tableau/dashboard_screenshot.png)

## Dataset Source

Medical Appointment No Shows dataset from Kaggle.

[Kaggle Dataset](https://www.kaggle.com/datasets/joniarroba/noshowappointments/data)

## Notes

- The appointment risk categories are based on custom SQL rules and are intended for exploratory analysis, not as a validated predictive model.
- Observed relationships do not necessarily indicate causation.
- Neighborhood comparisons were limited to neighborhoods with at least 100 appointments to reduce the impact of very small sample sizes.
