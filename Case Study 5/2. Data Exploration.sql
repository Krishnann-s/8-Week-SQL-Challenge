-- 2. Data Exploration
-- 1. What day of the week is used for each week_date value?
SELECT DISTINCT TO_CHAR(week_date, 'day') AS week_day
FROM clean_weakly_sales;

-- 2. What range of week numbers are missing from the dataset?
WITH CTE
AS (
	SELECT GENERATE_SERIES(1, 52) AS total_weeks
	)
SELECT DISTINCT total_weeks
FROM CTE AS c
LEFT JOIN clean_weakly_sales AS cws
	ON c.total_weeks = cws.week_number
WHERE cws.week_number IS NULL;

-- 3. How many total transactions were there for each year in the dataset?
SELECT EXTRACT('year' FROM cws.week_date) AS each_year
	,SUM(transactions)
FROM weekly_sales AS ws
INNER JOIN clean_weakly_sales AS cws
	ON ws.segment = cws.segment
WHERE ws.segment != 'null'
GROUP BY EXTRACT('year' FROM cws.week_date);

-- 4. What is the total sales for each region for each month?
SELECT region
	,month_number
	,SUM(ws.sales)
FROM weekly_sales AS ws
INNER JOIN clean_weakly_sales AS cws
	ON ws.segment = cws.segment
GROUP BY region
	,month_number
ORDER BY region
	,month_number;

-- 5. What is the total count of transactions for each platform
SELECT platform
	,SUM(transactions) AS transaction_count
FROM weekly_sales
GROUP BY platform;

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
WITH CTE
AS (
	SELECT year_number
		,month_number
		,platform
		,SUM(ws.sales) AS monthly_sales
	FROM clean_weakly_sales AS cws
	INNER JOIN weekly_sales AS ws
		ON cws.segment = ws.segment
	GROUP BY year_number
		,month_number
		,platform
	)
SELECT year_number
	,month_number
	,ROUND(100 * MAX(CASE 
				WHEN platform = 'Retail'
					THEN monthly_sales
				ELSE NULL
				END) / SUM(monthly_sales), 2) AS retail_percentage
	,ROUND(100 * MAX(CASE 
				WHEN platform = 'Shopify'
					THEN monthly_sales
				ELSE NULL
				END) / SUM(monthly_sales), 2) AS shopify_percentage
FROM CTE
GROUP BY year_number
	,month_number;

-- 7. What is the percentage of sales by demographic for each year in the dataset?
WITH CTE
AS (
	SELECT year_number
		,demographic
		,SUM(ws.sales) AS yearly_sales
	FROM clean_weakly_sales AS cws
	INNER JOIN weekly_sales AS ws
		ON cws.segment = ws.segment
	GROUP BY year_number
		,demographic
	)
	,total_sales
AS (
	SELECT *
		,SUM(yearly_sales) OVER (PARTITION BY year_number) AS total_sales
	FROM CTE
	)
SELECT year_number
	,demographic
	,ROUND(100 * yearly_sales / total_sales, 2) AS percent_sales_demographic
FROM total_sales
GROUP BY year_number
	,demographic
	,yearly_sales
	,total_sales;

-- 8. Which age_band and demographic values contribute the most to Retail sales?
SELECT age_band
	,demographic
	,ws.platform
	,SUM(ws.sales)
	,ROUND(100 * SUM(ws.sales)::NUMERIC / SUM(SUM(ws.sales)) OVER (), 1) AS contribution_percentage
FROM clean_weakly_sales AS cws
INNER JOIN weekly_sales AS ws
	ON cws.segment = ws.segment
GROUP BY age_band
	,demographic
	,ws.platform
ORDER BY SUM(ws.sales) DESC;

-- 9. Can we use the avg_transaction column to find the average transaction size 
-- for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT year_number
	,ws.platform
	,ROUND(SUM(sales) / SUM(transactions), 2) AS correct_avg
	,ROUND(AVG(avg_transaction), 2) AS incorrect_avg
FROM clean_weakly_sales AS cws
INNER JOIN weekly_sales AS ws
	ON cws.segment = ws.segment
GROUP BY year_number
	,platform
ORDER BY year_number
	,platform
