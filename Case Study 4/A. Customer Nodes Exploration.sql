-- A. Customer Nodes Exploration
-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS unique_node
FROM customer_nodes;

-- 2. What is the number of nodes per region?
SELECT region_name
	,COUNT(node_id) AS nodes
FROM customer_nodes AS c
INNER JOIN regions AS r
	ON c.region_id = r.region_id
GROUP BY region_name;

-- 3. How many customers are allocated to each region?
SELECT region_name
	,COUNT(DISTINCT customer_id) AS customer_count
FROM customer_nodes AS c
INNER JOIN regions AS r
	ON c.region_id = r.region_id
GROUP BY region_name;

-- 4. How many days on average are customers reallocated to a different node?
WITH CTE
AS (
	SELECT customer_id
		,node_id
		,SUM(EXTRACT('day' FROM end_date::TIMESTAMP - start_date::TIMESTAMP)) AS days
	FROM customer_nodes
	WHERE end_date != '9999-12-31'
	GROUP BY customer_id
		,node_id
	)
SELECT ROUND(AVG(days)) AS avg_days
FROM CTE;

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH CTE
AS (
	SELECT region_name
		,customer_id
		,node_id
		,SUM(EXTRACT('day' FROM end_date::TIMESTAMP - start_date::TIMESTAMP)) AS days
	FROM customer_nodes AS c
	INNER JOIN regions AS r
		ON r.region_id = c.region_id
	WHERE end_date != '9999-12-31'
	GROUP BY customer_id
		,node_id
		,region_name
	)
SELECT region_name
	,ROUND(AVG(days)) AS avg_day
	,PERCENTILE_CONT(0.5) WITHIN
GROUP (
		ORDER BY days
		) AS median
	,PERCENTILE_CONT(0.95) WITHIN
GROUP (
		ORDER BY days
		)::DECIMAL(10, 2) AS days_95_percentile
	,PERCENTILE_CONT(0.80) WITHIN
GROUP (
		ORDER BY days
		)::DECIMAL(10, 2) AS days_80_percentile
FROM CTE
GROUP BY region_name;
