-- 1. Data Cleansing Steps
-- In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
-- Convert the week_date to a DATE format
-- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January 
-- will be 1, 8th to 14th will be 2 etc
-- Add a month_number with the calendar month for each week_date value as the 3rd column
-- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
CREATE TABLE clean_weakly_sales AS

SELECT TO_DATE(week_date, 'DD/MM/YY') AS week_date
	,DATE_PART('week', TO_DATE(week_date, 'DD/MM/YY')) AS week_number
	,DATE_PART('month', TO_DATE(week_date, 'DD/MM/YY')) AS month_number
	,DATE_PART('year', TO_DATE(week_date, 'DD/MM/YY')) AS year_number
	,CASE 
		WHEN segment = 'null'
			THEN 'unknown'
		ELSE segment
		END AS segment
	,CASE 
		WHEN RIGHT(segment, 1) = '1'
			THEN 'Young Adult'
		WHEN RIGHT(segment, 1) = '2'
			THEN 'Middle Aged'
		WHEN RIGHT(segment, 1) IN (
				'3'
				,'4'
				)
			THEN 'Retirees'
		ELSE 'unknown'
		END AS age_band
	,CASE 
		WHEN LEFT(segment, 1) = 'C'
			THEN 'Couples'
		WHEN LEFT(segment, 1) = 'F'
			THEN 'Families'
		ELSE 'unknown'
		END AS demographic
	,ROUND((sales::NUMERIC / transactions), 2) AS avg_transaction
FROM weekly_sales;

SELECT *
FROM clean_weakly_sales LIMIT 100;
