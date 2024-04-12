-- B. Transaction Analysis
-- 1. How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id)
FROM balanced_tree.sales;

-- 2. What is the average unique products purchased in each transaction?
WITH CTE
AS (
	SELECT txn_id
		,SUM(qty) AS prod_count
	FROM balanced_tree.sales
	GROUP BY txn_id
	)
SELECT ROUND(AVG(prod_count), 0) AS Avg_products_purchased
FROM CTE;

-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH CTE
AS (
	SELECT txn_id
		,SUM(qty * price) AS revenue
	FROM balanced_tree.sales
	GROUP BY txn_id
	)
SELECT PERCENTILE_CONT(0.25) WITHIN
GROUP (
		ORDER BY revenue
		) AS percentile_25th
	,PERCENTILE_CONT(0.50) WITHIN
GROUP (
		ORDER BY revenue
		) AS percentile_50th
	,PERCENTILE_CONT(0.75) WITHIN
GROUP (
		ORDER BY revenue
		) AS percentile_75th
FROM CTE;

-- 4. What is the average discount value per transaction?
WITH discount
AS (
	SELECT txn_id
		,SUM(qty * price * discount / 100) AS total_discount
	FROM balanced_tree.sales
	GROUP BY txn_id
	)
SELECT ROUND(AVG(total_discount), 1) AS avg_discount_per_transaction
FROM discount;

-- 5. What is the percentage split of all transactions for members vs non-members?
WITH CTE
AS (
	SELECT member
		,COUNT(DISTINCT txn_id) AS transactions
	FROM balanced_tree.sales
	GROUP BY member
	)
SELECT CASE 
		WHEN member = 't'
			THEN 'Members'
		ELSE 'Non-Members'
		END AS Type
	,transactions
	,ROUND(100 * transactions / (
			SELECT SUM(transactions)
			FROM CTE
			)) AS percentage_split
FROM CTE;

-- 6. What is the average revenue for member transactions and non-member transactions?
WITH CTE
AS (
	SELECT member
		,txn_id
		,SUM(qty * price) AS revenue
	FROM balanced_tree.sales
	GROUP BY member
		,txn_id
	)
SELECT CASE 
		WHEN member = 't'
			THEN 'Members'
		ELSE 'Non-Members'
		END AS Type
	,ROUND(AVG(revenue), 2)
FROM CTE
GROUP BY 1
