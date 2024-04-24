-- running customer balance column that includes the impact each transaction
WITH transaction_amt_cte
AS (
	SELECT *
		,EXTRACT('month' FROM txn_date) AS txn_month
		,SUM(CASE 
				WHEN txn_type = 'deposit'
					THEN txn_amount
				ELSE - txn_amount
				END) AS net_transaction_amt
	FROM data_bank.customer_transactions
	GROUP BY customer_id
		,txn_date
		,txn_type
		,txn_amount
	ORDER BY customer_id
		,txn_date
	)
	,running_customer_balance_cte
AS (
	SELECT customer_id
		,txn_date
		,txn_month
		,txn_type
		,txn_amount
		,sum(net_transaction_amt) OVER (
			PARTITION BY customer_id ORDER BY txn_month ROWS BETWEEN UNBOUNDED preceding
					AND CURRENT ROW
			) AS running_customer_balance
	FROM transaction_amt_cte
	)
SELECT *
FROM running_customer_balance_cte;

-- customer balance at the end of each month
WITH transaction_amt_cte
AS (
	SELECT *
		,EXTRACT('month' FROM txn_date) AS txn_month
		,SUM(CASE 
				WHEN txn_type = 'deposit'
					THEN txn_amount
				ELSE - txn_amount
				END) AS net_transaction_amt
	FROM data_bank.customer_transactions
	GROUP BY customer_id
		,txn_date
		,txn_type
		,txn_amount
	ORDER BY customer_id
		,txn_date
	)
	,running_customer_balance_cte
AS (
	SELECT customer_id
		,txn_date
		,txn_month
		,txn_type
		,txn_amount
		,sum(net_transaction_amt) OVER (
			PARTITION BY customer_id ORDER BY txn_month ROWS BETWEEN UNBOUNDED preceding
					AND CURRENT ROW
			) AS running_customer_balance
	FROM transaction_amt_cte
	)
	,month_end_balance_cte
AS (
	SELECT *
		,last_value(running_customer_balance) OVER (
			PARTITION BY customer_id
			,txn_month ORDER BY txn_month
			) AS month_end_balance
	FROM running_customer_balance_cte
	GROUP BY customer_id
		,txn_month
		,txn_date
		,txn_type
		,txn_amount
		,running_customer_balance
	)
SELECT customer_id
	,txn_month
	,month_end_balance
FROM month_end_balance_cte;

-- minimum, average and maximum values of the running balance for each customer
WITH transaction_amt_cte
AS (
	SELECT *
		,EXTRACT('month' FROM txn_date) AS txn_month
		,SUM(CASE 
				WHEN txn_type = 'deposit'
					THEN txn_amount
				ELSE - txn_amount
				END) AS net_transaction_amt
	FROM data_bank.customer_transactions
	GROUP BY customer_id
		,txn_date
		,txn_type
		,txn_amount
	ORDER BY customer_id
		,txn_date
	)
	,running_customer_balance_cte
AS (
	SELECT customer_id
		,txn_date
		,txn_month
		,txn_type
		,txn_amount
		,sum(net_transaction_amt) OVER (
			PARTITION BY customer_id ORDER BY txn_month ROWS BETWEEN UNBOUNDED preceding
					AND CURRENT ROW
			) AS running_customer_balance
	FROM transaction_amt_cte
	GROUP BY customer_id
		,txn_month
		,txn_type
		,txn_amount
		,txn_date
		,net_transaction_amt
	)
SELECT customer_id
	,min(running_customer_balance)
	,max(running_customer_balance)
	,round(avg(running_customer_balance), 2) AS "avg(running_customer_balance)"
FROM running_customer_balance_cte
GROUP BY customer_id
ORDER BY customer_id;

-- Option 1: Data is allocated based off the amount of money at the end of the previous month
-- How much data would have been required on a monthly basis?
WITH transaction_amt_cte
AS (
	SELECT *
		,EXTRACT('month' FROM txn_date) AS txn_month
		,SUM(CASE 
				WHEN txn_type = 'deposit'
					THEN txn_amount
				ELSE - txn_amount
				END) AS net_transaction_amt
	FROM data_bank.customer_transactions
	GROUP BY customer_id
		,txn_date
		,txn_type
		,txn_amount
	ORDER BY customer_id
		,txn_date
	)
	,running_customer_balance_cte
AS (
	SELECT customer_id
		,txn_date
		,txn_month
		,txn_type
		,txn_amount
		,sum(net_transaction_amt) OVER (
			PARTITION BY customer_id ORDER BY txn_month ROWS BETWEEN UNBOUNDED preceding
					AND CURRENT ROW
			) AS running_customer_balance
	FROM transaction_amt_cte
	)
	,month_end_balance_cte
AS (
	SELECT *
		,last_value(running_customer_balance) OVER (
			PARTITION BY customer_id
			,txn_month ORDER BY txn_month
			) AS month_end_balance
	FROM running_customer_balance_cte
	)
	,customer_month_end_balance_cte
AS (
	SELECT customer_id
		,txn_month
		,month_end_balance
	FROM month_end_balance_cte
	GROUP BY customer_id
		,txn_month
		,month_end_balance
	)
SELECT txn_month
	,sum(CASE 
			WHEN month_end_balance > 0
				THEN month_end_balance
			ELSE 0
			END) AS data_required_per_month
FROM customer_month_end_balance_cte
GROUP BY txn_month
ORDER BY txn_month
