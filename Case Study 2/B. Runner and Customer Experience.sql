-- B. Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT COUNT(runner_id) AS Runners
	,CAST(DATE_TRUNC('week', registration_date) + INTERVAL '4 days' AS DATE) AS Week
FROM runners
GROUP BY DATE_TRUNC('week', registration_date) + INTERVAL '4 days';


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza 
-- Runner HQ to pickup the order?
SELECT runner_id
	,AVG(EXTRACT(MINUTE FROM (pickup_time::TIMESTAMP - order_time)))::NUMERIC(10, 2) AS duration_minutes
FROM runner_orders AS ro
INNER JOIN customer_orders AS co
	ON ro.order_id = co.order_id
WHERE duration != 'null'
GROUP BY runner_id
ORDER BY runner_id;


-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH CTE
AS (
	SELECT co.order_id
		,COUNT(pizza_id) AS number_of_pizzas
		,MAX(EXTRACT(MINUTE FROM (pickup_time::TIMESTAMP - order_time))) AS preparation_time
	FROM customer_orders co
	INNER JOIN runner_orders AS ro
		ON co.order_id = ro.order_id
	WHERE pickup_time != 'null'
	GROUP BY co.order_id
	ORDER BY co.order_id
	)
SELECT number_of_pizzas
	,aVG(preparation_time)::NUMERIC(10, 0) AS avg_prep_time
FROM CTE
GROUP BY number_of_pizzas
ORDER BY number_of_pizzas;


-- 4. What was the average distance travelled for each customer?
SELECT co.customer_id
	,AVG(REPLACE(distance, 'km', '')::NUMERIC(3, 1))::NUMERIC(3, 1) AS Avg_Distance
FROM runner_orders AS ro
INNER JOIN customer_orders AS co
	ON co.order_id = ro.order_id
WHERE distance != 'null'
GROUP BY co.customer_id
ORDER BY co.customer_id;


-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(REGEXP_REPLACE(duration, '[[:alpha:]]', '', 'g')::INT) - MIN(REGEXP_REPLACE(duration, '[[:alpha:]]', '', 'g')::INT) AS Time_Difference
FROM runner_orders
WHERE duration != 'null';


-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id
	,order_id
	,(AVG(REPLACE(distance, 'km', '')::NUMERIC(3, 1) * 1000 / REGEXP_REPLACE(duration, '[[:alpha:]]', '', 'g')::NUMERIC(3, 1)) * 0.06)::NUMERIC(10, 1) AS Avg_speed
FROM runner_orders
WHERE distance != 'null'
GROUP BY runner_id
	,order_id
ORDER BY runner_id
	,order_id;


-- 7. What is the successful delivery percentage for each runner?
SELECT runner_id
	,TRUNC(SUM(CASE 
				WHEN pickup_time = 'null'
					THEN 0
				ELSE 1
				END)::DECIMAL / COUNT(order_id), 2) AS Successful_delivery_percentage
FROM runner_orders
GROUP BY runner_id
ORDER BY runner_id;
