-- B. Customer Transactions
-- 1. What is the unique count and total amount for each transaction type?
SELECT txn_type
	,SUM(txn_amount) AS total_transaction_amount
	,COUNT(*) AS unique_count
FROM customer_transactions
GROUP BY txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
WITH CTE
AS (
	SELECT customer_id
		,AVG(txn_amount) AS deposit_avg
		,COUNT(*) AS unique_count
	FROM customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id
	)
SELECT ROUND(AVG(unique_count), 2) AS avg_transaction_amount
	,ROUND(AVG(deposit_avg), 2) AS Avg_historial_depost
FROM CTE;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH CTE
AS (
	SELECT EXTRACT('month' FROM txn_date) AS month
		,customer_id
		,SUM(CASE 
				WHEN txn_type = 'deposit'
					THEN 1
				ELSE 0
				END) AS deposits
		,SUM(CASE 
				WHEN txn_type <> 'deposit'
					THEN 1
				ELSE 0
				END) AS purchase_or_withdrawal
	FROM customer_transactions
	GROUP BY EXTRACT('month' FROM txn_date)
		,customer_id
	HAVING SUM(CASE 
				WHEN txn_type = 'deposit'
					THEN 1
				ELSE 0
				END) > 1
		AND SUM(CASE 
				WHEN txn_type <> 'deposit'
					THEN 1
				ELSE 0
				END) = 1
	)
SELECT month
	,COUNT(customer_id) AS customers
FROM CTE
GROUP BY month;

-- 4. What is the closing balance for each customer at the end of the month?
WITH CTE
AS (
	SELECT EXTRACT('month' FROM txn_date) AS txn_month
		,txn_date
		,customer_id
		,SUM((
				CASE 
					WHEN txn_type = 'deposit'
						THEN txn_amount
					ELSE 0
					END
				) - (
				CASE 
					WHEN txn_type != 'deposit'
						THEN txn_amount
					ELSE 0
					END
				)) AS balance
	FROM customer_transactions
	GROUP BY EXTRACT('month' FROM txn_date)
		,txn_date
		,customer_id
	)
	,BAL
AS (
	SELECT *
		,SUM(balance) OVER (
			PARTITION BY customer_id ORDER BY txn_date
			) AS running_sum
		,ROW_NUMBER() OVER (
			PARTITION BY customer_id
			,txn_month ORDER BY txn_date DESC
			) AS rn
	FROM CTE
	ORDER BY txn_date
	)
SELECT customer_id
	,txn_month
	,(DATE_TRUNC('day', DATE_TRUNC('month', txn_date) + INTERVAL '1 month') - INTERVAL '1 day')::DATE AS end_of_month
	,running_sum AS closing_balance
FROM BAL
WHERE rn = 1
ORDER BY customer_id;
