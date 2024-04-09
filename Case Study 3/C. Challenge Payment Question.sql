-- C. Challenge Payment Question
-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by 
-- each customer in the subscriptions table with the following requirements:
-- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts 
-- at the end of the month period
-- once a customer churns they will no longer make payments

CREATE TABLE payments_2020 (
	payment_id SERIAL PRIMARY KEY
	,customer_id INTEGER
	,payment_date DATE
	,amount DECIMAL(8, 2)
	);

-- Monthly payments
INSERT INTO payments_2020 (
	customer_id
	,payment_date
	,amount
	)
SELECT s.customer_id
	,DATE_TRUNC('month', s.start_date) + INTERVAL '1 month' - INTERVAL '1 day' AS payment_date
	,p.price
FROM subscriptions s
JOIN plans p
	ON s.plan_id = p.plan_id
WHERE s.start_date >= '2020-01-01'
	AND s.start_date < '2021-01-01'
	AND p.plan_name IN (
		'basic monthly'
		,'pro monthly'
		);

INSERT INTO payments_2020 (
	customer_id
	,payment_date
	,amount
	)
SELECT s.customer_id
	,DATE_TRUNC('month', s.start_date) + INTERVAL '1 month' - INTERVAL '1 day' AS payment_date
	,p.price - COALESCE(SUM(p.price), 0)
FROM subscriptions s
JOIN plans p
	ON s.plan_id = p.plan_id
LEFT JOIN payments_2020 p2
	ON s.customer_id = p2.customer_id
		AND DATE_TRUNC('month', s.start_date) = DATE_TRUNC('month', p2.payment_date)
WHERE s.start_date >= '2020-01-01'
	AND s.start_date < '2021-01-01'
	AND p.plan_name IN (
		'basic monthly'
		,'pro monthly'
		)
GROUP BY s.customer_id
	,s.start_date
	,p.price;

INSERT INTO payments_2020 (
	customer_id
	,payment_date
	,amount
	)
SELECT s.customer_id
	,DATE_TRUNC('month', s.start_date) + INTERVAL '1 month' - INTERVAL '1 day' AS payment_date
	,p.price
FROM subscriptions s
JOIN plans p
	ON s.plan_id = p.plan_id
WHERE s.start_date >= '2020-01-01'
	AND s.start_date < '2021-01-01'
	AND p.plan_name = 'pro annual';

UPDATE subscriptions
SET start_date = '2020-12-31'
WHERE start_date < '2020-12-31'
	AND customer_id NOT IN (
		SELECT DISTINCT customer_id
		FROM subscriptions
		WHERE start_date < '2021-01-01'
		);

SELECT *
FROM payments_2020;

WITH ranked_payments
AS (
	SELECT p.customer_id
		,s.plan_id
		,p.payment_date
		,p.amount
		,ROW_NUMBER() OVER (
			PARTITION BY p.customer_id
			,s.plan_id ORDER BY p.payment_date
			) AS payment_order
	FROM payments_2020 p
	JOIN subscriptions s
		ON p.customer_id = s.customer_id
	)
SELECT customer_id
	,rp.plan_id
	,plan_name
	,payment_date
	,amount
	,payment_order
FROM ranked_payments rp
JOIN plans p
	ON rp.plan_id = p.plan_id
ORDER BY customer_id
	,plan_id
	,payment_date;
