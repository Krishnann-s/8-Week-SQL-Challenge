-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
-- how much money has Pizza Runner made so far if there are no delivery fees?
SELECT runner_id
	,pn.pizza_name
	,CASE 
		WHEN pn.pizza_name = 'Meatlovers'
			THEN COUNT('Meatlovers') * 12
		ELSE COUNT('Vegetarian') * 10
		END AS total_cost
FROM customer_orders AS co
INNER JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
INNER JOIN pizza_names AS pn
	ON co.pizza_id = pn.pizza_id
WHERE cancellation IS NULL
	OR cancellation = 'null'
GROUP BY runner_id
	,pn.pizza_name
ORDER BY runner_id;


-- 2. What if there was an additional $1 charge for any pizza extras?
-- 		Add cheese is $1 extra
WITH PizzaOrders
AS (
	SELECT co.order_id
		,ro.runner_id
		,pn.pizza_name AS pizza_name
		,pt.topping_name AS topping_name
		,COUNT(CASE 
				WHEN pn.pizza_name = 'Meatlovers'
					THEN 1
				END) AS meatlovers_count
		,COUNT(CASE 
				WHEN pn.pizza_name = 'Vegetarian'
					THEN 1
				END) AS vegetarian_count
	FROM customer_orders AS co
	INNER JOIN runner_orders AS ro
		ON co.order_id = ro.order_id
	INNER JOIN pizza_names AS pn
		ON co.pizza_id = pn.pizza_id
	LEFT JOIN LATERAL(SELECT trim(split_part(extras, ',', i)) AS split_extras FROM generate_series(1, regexp_count(extras, ',') + 1) AS s(i)) AS t
		ON true
	LEFT JOIN pizza_toppings AS pt
		ON pt.topping_id::TEXT = t.split_extras
	WHERE cancellation IS NULL
		OR cancellation = 'null'
	GROUP BY co.order_id
		,ro.runner_id
		,pn.pizza_name
		,pt.topping_name
	)
SELECT runner_id
	,pizza_name
	,SUM(CASE 
			WHEN topping_name = 'Cheese'
				THEN (
						CASE 
							WHEN pizza_name = 'Meatlovers'
								THEN (12 * meatlovers_count) + 2
							ELSE (10 * vegetarian_count) + 2
							END
						)
			ELSE (
					CASE 
						WHEN pizza_name = 'Meatlovers'
							THEN (12 * meatlovers_count)
						ELSE (10 * vegetarian_count)
						END
					) + CASE 
					WHEN topping_name IS NOT NULL
						THEN 1
					ELSE 0
					END
			END) AS total_cost
FROM PizzaOrders
GROUP BY runner_id
	,pizza_name
ORDER BY runner_id;



-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate 
-- their runner, how would you design an additional table for this new dataset 
-- generate a schema for this new table and insert your own data for ratings for each successful 
-- customer order between 1 to 5.
DROP TABLE runner_ratings;
CREATE TABLE runner_ratings (
    rating_id SERIAL PRIMARY KEY,
    order_id INT,
    customer_id INT ,
    rating INT CHECK (rating >= 1 AND rating <= 5)
);
ALTER TABLE runner_ratings ADD runner_id INT;
INSERT INTO runner_ratings (order_id, runner_id, rating, customer_id)
VALUES
    (1, 1, 4,101),
    (2, 1, 5,101),  
    (3, 1, 5,102),  
    (4, 2, 4,103),  
    (5, 3, 4,104),  
    (6, 3, null,101),  
    (7, 2, 4,105),  
    (8, 2, 5,102),  
    (9, 2, null,103),  
    (10, 1, 5,104);
SELECT * FROM runner_ratings;

-- 4. Using your newly generated table - can you join all of the information together to form a table 
-- which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas
SELECT co.order_id
	,co.customer_id
	,ro.runner_id
	,rr.rating
	,co.order_time
	,ro.pickup_time
	,EXTRACT('minute' FROM (to_timestamp(ro.pickup_time, 'yy-mm-dd HH24:MI:SS.MS') - co.order_time)) AS time_between_order_and_pickup
	,REGEXP_REPLACE(duration, '[[:alpha:]]', '', 'g')::INT AS delivery_duration
	,(AVG(REPLACE(distance, 'km', '')::NUMERIC(3, 1) * 1000 / REGEXP_REPLACE(duration, '[[:alpha:]]', '', 'g')::NUMERIC(3, 1)) * 0.06)::NUMERIC(10, 1) AS Avg_speed
	,COUNT(co.pizza_id) AS total_number_of_pizzas
FROM customer_orders AS co
INNER JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
INNER JOIN runner_ratings AS rr
	ON co.order_id = rr.order_id
WHERE ro.cancellation IS NULL
	OR ro.cancellation = 'null'
	OR pickup_time != 'null'
GROUP BY co.customer_id
	,co.order_id
	,ro.runner_id
	,rr.rating
	,co.order_time
	,ro.pickup_time
	,ro.duration
ORDER BY co.order_id
	,co.customer_id
	,ro.runner_id;




-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and 
-- each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
WITH CTE
AS (
	SELECT runner_id
		,pn.pizza_name
		,(
			COUNT(CASE 
					WHEN pn.pizza_name = 'Meatlovers'
						THEN 1
					ELSE 0
					END) * (CAST(REPLACE(ro.distance, 'km', '') AS NUMERIC) * 0.3)
			) + (
			COUNT(CASE 
					WHEN pn.pizza_name != 'Meatlovers'
						THEN 1
					ELSE 0
					END) * (CAST(REPLACE(ro.distance, 'km', '') AS NUMERIC) * 0.3)
			) AS total_cost
		,ROW_NUMBER() OVER (
			PARTITION BY runner_id
			,pizza_name ORDER BY co.order_id
			) AS row_num
	FROM customer_orders AS co
	INNER JOIN runner_orders AS ro
		ON co.order_id = ro.order_id
	INNER JOIN pizza_names AS pn
		ON co.pizza_id = pn.pizza_id
	WHERE cancellation IS NULL
		OR cancellation = 'null'
		OR ro.distance != 'null'
	GROUP BY pn.pizza_name
		,runner_id
		,ro.distance
		,co.order_id
	ORDER BY runner_id
		,total_cost DESC
	)
SELECT runner_id
	,pizza_name
	,total_cost
FROM CTE
WHERE row_num = 1;
