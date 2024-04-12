-- A. Data Exploration and Cleansing
-- 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
ALTER TABLE fresh_segments.interest_metrics;

ALTER COLUMN month_year TYPE DATE USING TO_DATE (
	'01-' || month_year
	,'DD-MM-YYYY'
	);

SELECT *
FROM fresh_segments.interest_metrics;

-- 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order 
-- (earliest to latest) with the null values appearing first?
SELECT month_year
	,COUNT(*)
FROM fresh_segments.interest_metrics
GROUP BY month_year
ORDER BY month_year NULLS FIRST;

-- 3. What do you think we should do with these null values in the fresh_segments.interest_metrics
SELECT ROUND(100 * (
			SUM(CASE 
					WHEN interest_id IS NULL
						THEN 1
					END) * 1.0 / COUNT(*)
			), 2) AS null_percentage
FROM fresh_segments.interest_metrics;

DELETE
FROM fresh_segments.interest_metrics
WHERE interest_id IS NULL;

-- 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? 
-- What about the other way around?
SELECT COUNT(DISTINCT interest_id) AS interest_id_in_metrics
	,COUNT(DISTINCT id) AS interest_id_in_map
	,SUM(CASE 
			WHEN id IS NULL
				THEN 1
			END) AS not_in_metric
	,SUM(CASE 
			WHEN interest_id IS NULL
				THEN 1
			END) AS not_in_map
FROM fresh_segments.interest_metrics AS ime
FULL OUTER JOIN fresh_segments.interest_map AS ima
	ON ime.interest_id::INT = ima.id;

-- 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT id
	,interest_name
	,COUNT(*) AS total_record_count
FROM fresh_segments.interest_map AS ima
INNER JOIN fresh_segments.interest_metrics AS ime
	ON ima.id = ime.interest_id::INT
GROUP BY id
	,interest_name
ORDER BY 3 DESC
	,id;

-- 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 
-- in your joined output and include all columns from fresh_segments.interest_metrics and all columns from 
-- fresh_segments.interest_map except from the id column.
SELECT *
FROM fresh_segments.interest_map AS ima
INNER JOIN fresh_segments.interest_metrics AS ime
	ON ima.id = ime.interest_id::INT
-- need to filter out the null values present in month, year and month_yea
WHERE ime.interest_id = '21246'
	AND ime._month IS NOT NULL;

-- 7. Are there any records in your joined table where the month_year value is before the created_at value from the 
-- fresh_segments.interest_map table? Do you think these values are valid and why?
SELECT COUNT(*)
FROM fresh_segments.interest_map AS ima
INNER JOIN fresh_segments.interest_metrics AS ime
	ON ima.id = ime.interest_id::INT
WHERE ime.month_year < ima.created_at
