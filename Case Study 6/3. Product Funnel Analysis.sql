-- 3. Product Funnel Analysis
-- Using a single SQL query - create a new output table which has the following details:
-- 1. How many times was each product viewed?
-- 2. How many times was each product added to cart?
-- 3. How many times was each product added to a cart but not purchased (abandoned)?
-- 4. How many times was each product purchased?
WITH product_page_events
AS (
	SELECT e.visit_id
		,ph.product_id
		,ph.page_name AS product_name
		,ph.product_category
		,SUM(CASE 
				WHEN e.event_type = 1
					THEN 1
				ELSE 0
				END) AS page_view
		,SUM(CASE 
				WHEN e.event_type = 2
					THEN 1
				ELSE 0
				END) AS cart_add
	FROM clique_bait.events AS e
	JOIN clique_bait.page_hierarchy AS ph
		ON e.page_id = ph.page_id
	WHERE product_id IS NOT NULL
	GROUP BY e.visit_id
		,ph.product_id
		,ph.page_name
		,ph.product_category
	)
	,purchase_events
AS (
	SELECT DISTINCT visit_id
	FROM clique_bait.events
	WHERE event_type = 3
	)
	,combined_table
AS (
	SELECT ppe.visit_id
		,ppe.product_id
		,ppe.product_name
		,ppe.product_category
		,ppe.page_view
		,ppe.cart_add
		,CASE 
			WHEN pe.visit_id IS NOT NULL
				THEN 1
			ELSE 0
			END AS purchase
	FROM product_page_events AS ppe
	LEFT JOIN purchase_events AS pe
		ON ppe.visit_id = pe.visit_id
	)
	,product_info
AS (
	SELECT product_name
		,product_category
		,SUM(page_view) AS VIEWS
		,SUM(cart_add) AS cart_adds
		,SUM(CASE 
				WHEN cart_add = 1
					AND purchase = 0
					THEN 1
				ELSE 0
				END) AS abandoned
		,SUM(CASE 
				WHEN cart_add = 1
					AND purchase = 1
					THEN 1
				ELSE 0
				END) AS purchases
	FROM combined_table
	GROUP BY product_id
		,product_name
		,product_category
	)
SELECT *
FROM product_info;

-- Additionally, create another table which further aggregates the data for the above points but 
-- this time for each product category instead of individual products.
WITH product_page_events
AS (
	SELECT e.visit_id
		,ph.product_id
		,ph.page_name AS product_name
		,ph.product_category
		,SUM(CASE 
				WHEN e.event_type = 1
					THEN 1
				ELSE 0
				END) AS page_view
		,SUM(CASE 
				WHEN e.event_type = 2
					THEN 1
				ELSE 0
				END) AS cart_add
	FROM clique_bait.events AS e
	JOIN clique_bait.page_hierarchy AS ph
		ON e.page_id = ph.page_id
	WHERE product_id IS NOT NULL
	GROUP BY e.visit_id
		,ph.product_id
		,ph.page_name
		,ph.product_category
	)
	,purchase_events
AS (
	SELECT DISTINCT visit_id
	FROM clique_bait.events
	WHERE event_type = 3
	)
	,combined_table
AS (
	SELECT ppe.visit_id
		,ppe.product_id
		,ppe.product_name
		,ppe.product_category
		,ppe.page_view
		,ppe.cart_add
		,CASE 
			WHEN pe.visit_id IS NOT NULL
				THEN 1
			ELSE 0
			END AS purchase
	FROM product_page_events AS ppe
	LEFT JOIN purchase_events AS pe
		ON ppe.visit_id = pe.visit_id
	)
	,product_category
AS (
	SELECT product_category
		,SUM(page_view) AS VIEWS
		,SUM(cart_add) AS cart_adds
		,SUM(CASE 
				WHEN cart_add = 1
					AND purchase = 0
					THEN 1
				ELSE 0
				END) AS abandoned
		,SUM(CASE 
				WHEN cart_add = 1
					AND purchase = 1
					THEN 1
				ELSE 0
				END) AS purchases
	FROM combined_table
	GROUP BY product_category
	)
SELECT *
FROM product_category;

-- Use your 2 new output tables - answer the following questions:
-- 1. Which product had the most views, cart adds and purchases?
-- ANSWER:
-- Most viewed Product is Oyster
-- Product with most number of cart adds is Lobster
-- Product which was purchased the most is Lobster
-- 2. Which product was most likely to be abandoned?
-- ASNWER: 
-- Product which is Most likely to be abandoned is Russian Caviar
-- 3. Which product had the highest view to purchase percentage?
SELECT product_name
	,product_category
	,ROUND(100 * purchases / VIEWS, 2) AS purchase_per_view_percentage
FROM product_info
ORDER BY purchase_per_view_percentage DESC

-- 4. What is the average conversion rate from view to cart add?
SELECT ROUND(100 * AVG(cart_adds / VIEWS), 2) AS avg_views_to_cart_add_conversion
FROM product_info

-- 5. What is the average conversion rate from cart add to purchase?
SELECT ROUND(100 * AVG(purchases / cart_adds), 2) AS avg_cart_add_to_purchases_conversion_rate
FROM product_info
