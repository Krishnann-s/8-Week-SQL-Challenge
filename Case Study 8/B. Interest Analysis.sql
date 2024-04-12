-- B. Interest Analysis
-- 1. Which interests have been present in all month_year dates in our dataset?
SELECT COUNT(DISTINCT month_year) AS mon_year_count,
	COUNT(DISTINCT interest_id) AS interest_count
FROM fresh_segments.interest_metrics;

-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - 
-- which total_months value passes the 90% cumulative percentage value?
WITH CTE AS(
	SELECT interest_id, 
	MAX(EXTRACT('month' FROM month_year)) AS total_months
	FROM fresh_segments.interest_metrics
	WHERE interest_id IS NOT NULL
	GROUP BY interest_id
), INTEREST_COUNT AS(
SELECT total_months,
COUNT(DISTINCT interest_id) AS interest_count
FROM CTE
GROUP BY total_months
)
SELECT total_months, interest_count,
ROUND(100 * SUM(interest_count) OVER(ORDER BY total_months DESC) / (SUM(INTEREST_COUNT) OVER()), 2) AS cumulative_percentage
FROM INTEREST_COUNT;

-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - 
-- how many total data points would we be removing?
WITH CTE AS(
	SELECT interest_id, 
	MAX(EXTRACT('month' FROM month_year)) AS total_months
	FROM fresh_segments.interest_metrics
	WHERE interest_id IS NOT NULL
	GROUP BY interest_id
), INTEREST_COUNT AS(
SELECT total_months,
COUNT(DISTINCT interest_id) AS interest_count
FROM CTE
GROUP BY total_months
)
SELECT total_months, interest_count
FROM INTEREST_COUNT
WHERE interest_count < total_months

-- 4. Does this decision make sense to remove these data points from a business perspective? 
-- Use an example where there are all 14 months present to a removed interest example for your arguments - 
-- think about what it means to have less months present from a segment perspective.


-- 5. After removing these interests - how many unique interests are there for each month?