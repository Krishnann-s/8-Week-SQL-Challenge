-- A. Pizza Metrics
-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS pizzas_ordered
FROM customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT (order_id)) AS unique_orders
FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT COUNT(DISTINCT ORDER - id) AS total_orders_delivered
FROM runner_orders
WHERE pickup_time != 'null';

-- 4. How many of each type of pizza was delivered?
SELECT pn.pizza_name
	,COUNT(co.pizza_id) AS pizzas_delivered
FROM runner_orders AS RO
INNER JOIN customer_orders AS co
	ON ro.order_id = co.order_id
INNER JOIN pizza_names AS pn
	ON co.pizza_id = pn.pizza_id
WHERE pickup_time != 'null'
GROUP BY pn.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT co.customer_id
	,pn.pizza_name
	,COUNT(co.pizza_id) AS pizzas_ordered
FROM customer_orders AS co
INNER JOIN pizza_names AS pn
	ON co.pizza_id = pn.pizza_id
GROUP BY pn.pizza_name
	,co.customer_id
ORDER BY co.customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT co.order_id
	,COUNT(pizza_id) AS pizzas_ordered
FROM customer_orders AS co
INNER JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE pickup_time != 'null'
GROUP BY co.order_id
ORDER BY COUNT(pizza_id) DESC LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT customer_id
	,SUM(CASE 
			WHEN (
					(
						exclusions IS NOT NULL
						AND exclusions != 'null'
						AND LENGTH(exclusions) > 0
						)
					AND (
						extras IS NOT NULL
						AND extras != 'null'
						AND LENGTH(extras) > 0
						)
					) = TRUE
				THEN 1
			ELSE 0
			END) AS changes
	,SUM(CASE 
			WHEN (
					(
						exclusions IS NOT NULL
						AND exclusions != 'null'
						AND LENGTH(exclusions) > 0
						)
					AND (
						extras IS NOT NULL
						AND extras != 'null'
						AND LENGTH(extras) > 0
						)
					) = TRUE
				THEN 0
			ELSE 1
			END) AS no_changes
FROM customer_orders AS co
INNER JOIN runner_orders AS ro
	ON ro.order_id = co.order_id
WHERE pickup_time != 'null'
GROUP BY customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(pizza_id) AS pizza_delivered
FROM customer_orders co
INNER JOIN runner_orders AS ro
	ON ro.order_id = co.order_id
WHERE pickup_time != 'null'
	AND exclusions IS NOT NULL
	AND exlusions != 'null'
	AND LENGTH(exclusions) > 0
	AND extras IS NOT NULL
	AND extras != 'null'
	AND LENGTH(extras) > 0;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT DATE_PART('hour', order_time) AS hour
	,COUNT(pizza_id) AS total_pizzas_ordered
FROM customer_orders
GROUP BY DATE_PART('hour', order_time)
ORDER BY DATE_PART('hour', order_time);

-- 10. What was the volume of orders for each day of the week?
SELECT TO_CHAR(order_time, 'day') AS day_name
	,COUNT(pizza_id) AS total_pizzas_ordered
FROM customer_orders
GROUP BY DATE_PART('dow', order_time)
	,TO_CHAR(order_time, 'day')
ORDER BY DATE_PART('dow', order_time);
