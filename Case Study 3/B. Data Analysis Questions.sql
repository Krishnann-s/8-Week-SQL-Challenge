-- B. Data Analysis Questions
-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT (customer_id)) AS total_customer
FROM subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset 
-- use the start of the month as the group by value
SELECT DATE_TRUNC('month', start_date)::DATE AS monthly
	,COUNT(customer_id) AS monthly_subscribers
FROM subscriptions
WHERE plan_id = 0
GROUP BY DATE_TRUNC('month', start_date)
ORDER BY DATE_TRUNC('month', start_date);

-- 3. What plan start_date values occur after the year 2020 for our dataset? 
-- Show the breakdown by count of events for each plan_name
SELECT p.plan_id
	,plan_name
	,COUNT(*) AS count_of_events
FROM plans AS p
INNER JOIN subscriptions AS s
	ON p.plan_id = s.plan_id
WHERE DATE_PART('year', start_date) > 2020
GROUP BY plan_name
	,p.plan_id
ORDER BY p.plan_id;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT COUNT(DISTINCT (customer_id)) AS customer_count
	,ROUND(100 * COUNT(DISTINCT customer_id) / (
			SELECT COUNT(DISTINCT customer_id)
			FROM subscriptions
			), 1) AS churned_percentage
FROM subscriptions
WHERE plan_id = 4;

-- 5. How many customers have churned straight after their initial free trial 
-- what percentage is this rounded to the nearest whole number?
WITH CTE
AS (
	SELECT customer_id
		,plan_id
		,COUNT(DISTINCT customer_id) AS distinct_customer
		,ROW_NUMBER() OVER (
			PARTITION BY customer_id ORDER BY start_date ASC
			) AS rn
	FROM subscriptions
	GROUP BY start_date
		,customer_id
		,plan_id
	)
SELECT COUNT(*) AS churned_after_trial
	,ROUND(100 * COUNT(DISTINCT customer_id) / (
			SELECT COUNT(DISTINCT customer_id)
			FROM subscriptions
			), 0) AS churned_percentage
FROM CTE
WHERE rn = 2
	AND plan_id = 4
GROUP BY distinct_customer;

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH CTE
AS (
	SELECT customer_id
		,plan_name
		,ROW_NUMBER() OVER (
			PARTITION BY customer_id ORDER BY start_date ASC
			) AS rn
	FROM subscriptions AS s
	INNER JOIN plans AS p
		ON s.plan_id = p.plan_id
	)
SELECT plan_name
	,COUNT(customer_id) AS count_of_customer
	,CONCAT (
		ROUND(100 * COUNT(customer_id) / (
				SELECT COUNT(DISTINCT customer_id)
				FROM subscriptions
				), 1)
		,'%'
		) AS customer_percentage
FROM CTE
WHERE rn = 2
GROUP BY plan_name
ORDER BY COUNT(customer_id);

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH CTE
AS (
	SELECT *
		,ROW_NUMBER() OVER (
			PARTITION BY customer_id ORDER BY start_date DESC
			) AS rn
	FROM subscriptions
	WHERE start_date <= '2020-12-31'
	)
SELECT plan_name
	,COUNT(customer_id) AS customer_count
	,CONCAT (
		ROUND(100 * COUNT(customer_id) / (
				SELECT COUNT(DISTINCT customer_id)
				FROM subscriptions
				), 1)
		,'%'
		) AS customer_percentage
FROM CTE
INNER JOIN plans AS p
	ON CTE.plan_id = p.plan_id
WHERE rn = 1
GROUP BY plan_name
ORDER BY COUNT(customer_id);

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT plan_name
	,COUNT(customer_id) AS total_upgraded_customers
FROM subscriptions AS s
INNER JOIN plans AS p
	ON s.plan_id = p.plan_id
WHERE DATE_PART('year', start_date) = 2020
	AND plan_name = 'pro annual'
GROUP BY plan_name;

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH TRIAL
AS (
	SELECT customer_id
		,start_date AS trial_start
	FROM subscriptions
	WHERE plan_id = 0
	)
	,PRO
AS (
	SELECT customer_id
		,start_date AS pro_start
	FROM subscriptions
	WHERE plan_id = 3
	)
SELECT ROUND(AVG(EXTRACT(day FROM pro_start::TIMESTAMP - trial_start::TIMESTAMP)), 0) AS Avg_date_diff
FROM TRIAL t
INNER JOIN PRO AS p
	ON t.customer_id = p.customer_id;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH TRIAL
AS (
	SELECT customer_id
		,start_date AS trial_start
	FROM subscriptions
	WHERE plan_id = 0
	)
	,PRO
AS (
	SELECT customer_id
		,start_date AS pro_start
	FROM subscriptions
	WHERE plan_id = 3
	)
SELECT CASE 
		WHEN EXTRACT(day FROM pro_start::TIMESTAMP - trial_start::TIMESTAMP) <= 30
			THEN '0-30'
		WHEN EXTRACT(day FROM pro_start::TIMESTAMP - trial_start::TIMESTAMP) <= 60
			THEN '31-60'
		WHEN EXTRACT(day FROM pro_start::TIMESTAMP - trial_start::TIMESTAMP) <= 90
			THEN '61-90'
		WHEN EXTRACT(day FROM pro_start::TIMESTAMP - trial_start::TIMESTAMP) <= 120
			THEN '91-120'
		WHEN EXTRACT(day FROM pro_start::TIMESTAMP - trial_start::TIMESTAMP) <= 150
			THEN '121-150'
		WHEN EXTRACT(day FROM pro_start::TIMESTAMP - trial_start::TIMESTAMP) <= 180
			THEN '151-180'
		WHEN EXTRACT(day FROM pro_start::TIMESTAMP - trial_start::TIMESTAMP) <= 210
			THEN '181-210'
		WHEN EXTRACT(day FROM pro_start::TIMESTAMP - trial_start::TIMESTAMP) <= 240
			THEN '211-240'
		WHEN EXTRACT(day FROM pro_start::TIMESTAMP - trial_start::TIMESTAMP) <= 270
			THEN '241-270'
		WHEN EXTRACT(day FROM pro_start::TIMESTAMP - trial_start::TIMESTAMP) <= 300
			THEN '271-300'
		WHEN EXTRACT(day FROM pro_start::TIMESTAMP - trial_start::TIMESTAMP) <= 330
			THEN '301-330'
		WHEN EXTRACT(day FROM pro_start::TIMESTAMP - trial_start::TIMESTAMP) <= 360
			THEN '331-360'
		END AS day_periods
	,COUNT(t.customer_id) AS customer_count
FROM TRIAL t
INNER JOIN PRO AS p
	ON t.customer_id = p.customer_id
GROUP BY 1
ORDER BY 1;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH PRO_MON
AS (
	SELECT customer_id
		,start_date AS promon_date
	FROM subscriptions
	WHERE plan_id = 2
	)
	,BASIC
AS (
	SELECT customer_id
		,start_date AS basic_date
	FROM subscriptions
	WHERE plan_id = 1
	)
SELECT pm.customer_id
	,promon_date
	,basic_date
FROM PRO_MON AS pm
INNER JOIN BASIC AS b
	ON pm.customer_id = b.customer_id
WHERE promon_date < basic_date
	AND DATE_PART('year', basic_date) = 2020
