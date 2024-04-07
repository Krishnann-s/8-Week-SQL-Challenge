-- 1. What are the standard ingredients for each pizza?
SELECT pt.topping_name
FROM pizza_recipes AS pr
LEFT JOIN LATERAL(SELECT trim(split_part(toppings, ',', i))::INT AS split_topping FROM generate_series(1, regexp_count(toppings, ',') + 1) AS s(i)) AS t
	ON true
INNER JOIN pizza_toppings AS pt
	ON pt.topping_id = t.split_topping
GROUP BY pt.topping_name
HAVING COUNT(DISTINCT (pizza_id)) = 2;


-- 2. What was the most commonly added extra?
SELECT pt.topping_name
	,COUNT(pizza_id) AS extras_added
FROM customer_orders
LEFT JOIN LATERAL(SELECT trim(split_part(extras, ',', i)) AS split_extras FROM generate_series(1, regexp_count(extras, ',') + 1) AS s(i)) AS t
	ON true
INNER JOIN pizza_toppings AS pt
	ON pt.topping_id::TEXT = t.split_extras
WHERE extras != 'null'
	AND LENGTH(t.split_extras) > 0
GROUP BY pt.topping_name
ORDER BY COUNT(pizza_id) DESC LIMIT 1;


-- 3. What was the most common exclusion?
SELECT pt.topping_name
	,COUNT(pizza_id) AS common_exclusions
FROM customer_orders
LEFT JOIN LATERAL(SELECT trim(split_part(exclusions, ',', i)) AS split_exclusions FROM generate_series(1, regexp_count(exclusions, ',') + 1) AS s(i)) AS t
	ON true
INNER JOIN pizza_toppings AS pt
	ON pt.topping_id::TEXT = t.split_exclusions
WHERE exclusions != 'null'
	AND LENGTH(t.split_exclusions) > 0
GROUP BY pt.topping_name
ORDER BY COUNT(pizza_id) DESC LIMIT 1;


-- 4. Generate an order item for each record in the customers_orders table in 
-- the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH EXTRAS
AS (
	SELECT co.pizza_id
		,co.order_id
		,co.extras
		,STRING_AGG(DISTINCT pt.topping_name, ', ') AS extra_toppings
	FROM customer_orders AS co
	LEFT JOIN LATERAL(SELECT trim(split_part(extras, ',', i)) AS split_extras FROM generate_series(1, regexp_count(extras, ',') + 1) AS s(i)) AS t
		ON true
	INNER JOIN pizza_toppings AS pt
		ON pt.topping_id::TEXT = t.split_extras
	WHERE extras != 'null'
		AND LENGTH(t.split_extras) > 0
	GROUP BY co.pizza_id
		,co.order_id
		,co.extras
	)
	,EXCLUSIONS
AS (
	SELECT co.pizza_id
		,co.order_id
		,co.exclusions
		,STRING_AGG(DISTINCT pt.topping_name, ', ') AS excluded_toppings
	FROM customer_orders AS co
	LEFT JOIN LATERAL(SELECT trim(split_part(exclusions, ',', i)) AS split_exclusions FROM generate_series(1, regexp_count(exclusions, ',') + 1) AS s(i)) AS t
		ON true
	INNER JOIN pizza_toppings AS pt
		ON pt.topping_id::TEXT = t.split_exclusions
	WHERE extras != 'null'
		AND LENGTH(t.split_exclusions) > 0
	GROUP BY co.pizza_id
		,co.order_id
		,co.exclusions
	)
SELECT co.order_id
	,CONCAT (
		CASE 
			WHEN pn.pizza_name = 'Meatlovers'
				THEN 'Meat Lovers '
			ELSE pn.pizza_name
			END
		,COALESCE('- Extra ' || extra_toppings, '')
		,COALESCE('- Exclude ' || excluded_toppings, '')
		) AS order_details
FROM customer_orders AS co
LEFT JOIN EXTRAS AS ext
	ON ext.order_id = co.order_id
		AND ext.pizza_id = co.pizza_id
		AND ext.extras = co.extras
LEFT JOIN EXCLUSIONS AS exc
	ON exc.order_id = co.order_id
		AND exc.pizza_id = co.pizza_id
		AND exc.exclusions = co.exclusions
INNER JOIN pizza_names AS pn
	ON pn.pizza_id = co.pizza_id
ORDER BY order_id;



-- 5. Generate an alphabetically ordered comma separated ingredient list for each 
-- pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
WITH EXTRAS
AS (
	SELECT co.pizza_id
		,co.order_id
		,co.extras
		,pt.topping_id
		,pt.topping_name
	FROM customer_orders AS co
	LEFT JOIN LATERAL(SELECT trim(split_part(extras, ',', i)) AS split_extras FROM generate_series(1, regexp_count(extras, ',') + 1) AS s(i)) AS t
		ON true
	INNER JOIN pizza_toppings AS pt
		ON pt.topping_id::TEXT = t.split_extras
	WHERE extras != 'null'
		AND LENGTH(t.split_extras) > 0
	)
	,EXCLUSIONS
AS (
	SELECT co.pizza_id
		,co.order_id
		,co.exclusions
		,pt.topping_id
		,pt.topping_name AS excluded_toppings
	FROM customer_orders AS co
	LEFT JOIN LATERAL(SELECT trim(split_part(exclusions, ',', i)) AS split_exclusions FROM generate_series(1, regexp_count(exclusions, ',') + 1) AS s(i)) AS t
		ON true
	INNER JOIN pizza_toppings AS pt
		ON pt.topping_id::TEXT = t.split_exclusions
	WHERE extras != 'null'
		AND LENGTH(t.split_exclusions) > 0
	)
	,ORDERS
AS (
	SELECT co.order_id
		,co.pizza_id
		,pt.topping_id
		,pt.topping_name
	FROM customer_orders AS co
	INNER JOIN pizza_recipes AS pr
		ON co.pizza_id = pr.pizza_id
	LEFT JOIN LATERAL(SELECT trim(split_part(toppings, ',', i)) AS split_toppings FROM generate_series(1, regexp_count(toppings, ',') + 1) AS s(i)) AS t
		ON true
	INNER JOIN pizza_toppings AS pt
		ON pt.topping_id::TEXT = t.split_toppings
	)
	,ORDERS_WITH_EXTRAS_EXCLUSIONS
AS (
	SELECT o.order_id
		,o.pizza_id
		,o.topping_id
		,o.topping_name
	FROM ORDERS AS o
	LEFT JOIN EXCLUSIONS AS exc
		ON exc.order_id = o.order_id
			AND exc.pizza_id = o.pizza_id
			AND exc.topping_id = exc.topping_id
	WHERE exc.topping_id IS NULL
	
	UNION ALL
	
	SELECT order_id
		,pizza_id
		,topping_id
		,topping_name
	FROM EXTRAS
	)
	,TOTAL_INGREDIANT
AS (
	SELECT order_id
		,pn.pizza_name
		,topping_name
		,COUNT(topping_id) AS total_count
	FROM ORDERS_WITH_EXTRAS_EXCLUSIONS AS o
	INNER JOIN pizza_names AS pn
		ON pn.pizza_id = o.pizza_id
	GROUP BY order_id
		,pn.pizza_name
		,topping_name
	ORDER BY order_id
		,pn.pizza_name
		,topping_name
	)
	,FINALCTE
AS (
	SELECT order_id
		,pizza_name
		,STRING_AGG(DISTINCT CASE 
				WHEN total_count > 1
					THEN total_count || 'x' || topping_name
				ELSE topping_name
				END, ', ') AS ingrediant
	FROM TOTAL_INGREDIANT
	GROUP BY order_id
		,pizza_name
	)
SELECT order_id
	,pizza_name || ': ' || ingrediant AS ingrediants_list
FROM FINALCTE;


-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH EXTRAS
AS (
	SELECT co.pizza_id
		,co.order_id
		,co.extras
		,pt.topping_id
		,pt.topping_name
	FROM customer_orders AS co
	LEFT JOIN LATERAL(SELECT trim(split_part(extras, ',', i)) AS split_extras FROM generate_series(1, regexp_count(extras, ',') + 1) AS s(i)) AS t
		ON true
	INNER JOIN pizza_toppings AS pt
		ON pt.topping_id::TEXT = t.split_extras
	WHERE extras != 'null'
		AND LENGTH(t.split_extras) > 0
	)
	,EXCLUSIONS
AS (
	SELECT co.pizza_id
		,co.order_id
		,co.exclusions
		,pt.topping_id
		,pt.topping_name AS excluded_toppings
	FROM customer_orders AS co
	LEFT JOIN LATERAL(SELECT trim(split_part(exclusions, ',', i)) AS split_exclusions FROM generate_series(1, regexp_count(exclusions, ',') + 1) AS s(i)) AS t
		ON true
	INNER JOIN pizza_toppings AS pt
		ON pt.topping_id::TEXT = t.split_exclusions
	WHERE extras != 'null'
		AND LENGTH(t.split_exclusions) > 0
	)
	,ORDERS
AS (
	SELECT co.order_id
		,co.pizza_id
		,pt.topping_id
		,pt.topping_name
	FROM customer_orders AS co
	INNER JOIN pizza_recipes AS pr
		ON co.pizza_id = pr.pizza_id
	LEFT JOIN LATERAL(SELECT trim(split_part(toppings, ',', i)) AS split_toppings FROM generate_series(1, regexp_count(toppings, ',') + 1) AS s(i)) AS t
		ON true
	INNER JOIN pizza_toppings AS pt
		ON pt.topping_id::TEXT = t.split_toppings
	)
	,ORDERS_WITH_EXTRAS_EXCLUSIONS
AS (
	SELECT o.order_id
		,o.pizza_id
		,o.topping_id
		,o.topping_name
	FROM ORDERS AS o
	LEFT JOIN EXCLUSIONS AS exc
		ON exc.order_id = o.order_id
			AND exc.pizza_id = o.pizza_id
			AND exc.topping_id = exc.topping_id
	WHERE exc.topping_id IS NULL
	
	UNION ALL
	
	SELECT order_id
		,pizza_id
		,topping_id
		,topping_name
	FROM EXTRAS
	)
SELECT topping_name
	,COUNT(topping_id) AS total_use
FROM ORDERS_WITH_EXTRAS_EXCLUSIONS AS o
INNER JOIN runner_orders AS ro
	ON o.order_id = ro.order_id
WHERE cancellation = 'null'
	OR cancellation IS NULL
	OR cancellation = ''
GROUP BY topping_name
ORDER BY COUNT(topping_id) DESC;



