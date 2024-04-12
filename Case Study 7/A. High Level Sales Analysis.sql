-- A. High Level Sales Analysis
-- 1. What was the total quantity sold for all products?
SELECT product_name
	,SUM(qty)
FROM balanced_tree.sales AS s
INNER JOIN balanced_tree.product_details AS pd
	ON s.prod_id = pd.product_id
GROUP BY product_name;

-- 2. What is the total generated revenue for all products before discounts?
SELECT product_name
	,SUM(qty) * SUM(s.price) AS total_revenue
FROM balanced_tree.sales AS s
INNER JOIN balanced_tree.product_details AS pd
	ON s.prod_id = pd.product_id
GROUP BY product_name;

-- 3. What was the total discount amount for all products?
SELECT product_name
	,SUM(s.qty * s.price * discount / 100) AS total_discount
FROM balanced_tree.sales AS s
INNER JOIN balanced_tree.product_details AS pd
	ON s.prod_id = pd.product_id
GROUP BY product_name;
