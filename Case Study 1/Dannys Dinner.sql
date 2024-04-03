-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id
	,sum(price) AS Total_amount
FROM sales AS s
INNER JOIN menu AS M
	ON s.product_id = M.product_id
GROUP BY customer_id
ORDER BY total_amount DESC;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id
	,COUNT(DISTINCT (order_date)) AS visited_days
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH CTE
AS (
	SELECT customer_id
		,product_name
		,ROW_NUMBER() OVER (
			PARTITION BY customer_id ORDER BY order_date ASC
			) AS rn
	FROM sales AS s
	INNER JOIN menu AS m
		ON s.product_id = m.product_id
	)
SELECT customer_id
	,product_name
FROM CTE
WHERE rn = 1;

-- 4. What is the most purchased item on the menu 
-- and how many times was it purchased by all customers?
SELECT product_name
	,count(order_date) AS Orders
FROM sales AS s
INNER JOIN menu AS m
	ON s.product_id = m.product_id
GROUP BY product_name LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH CTE
AS (
	SELECT product_name
		,customer_id
		,count(order_date) AS Orders
		,RANK() OVER (
			PARTITION BY customer_id ORDER BY COUNT(order_date) DESC
			) AS rnk
	FROM sales AS s
	INNER JOIN menu AS m
		ON s.product_id = m.product_id
	GROUP BY product_name
		,customer_id
	ORDER BY customer_id
	)
SELECT product_name
	,customer_id
	,orders
FROM CTE
WHERE rnk = 1
-- 6. Which item was purchased first by the customer after they became a member?
WITH CTE AS (
		SELECT s.customer_id
			,order_date
			,product_name
			,join_date
			,RANK() OVER (
				PARTITION BY s.customer_id ORDER BY order_date
				) AS rnk
		FROM sales AS s
		INNER JOIN members AS mem
			ON s.customer_id = mem.customer_id
		INNER JOIN menu AS m
			ON s.product_id = m.product_id
		WHERE order_date >= join_date
		)

SELECT customer_id
	,product_name
FROM CTE
WHERE rnk = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH CTE
AS (
	SELECT s.customer_id
		,order_date
		,product_name
		,join_date
		,RANK() OVER (
			PARTITION BY s.customer_id ORDER BY order_date DESC
			) AS rnk
	FROM sales AS s
	INNER JOIN members AS mem
		ON s.customer_id = mem.customer_id
	INNER JOIN menu AS m
		ON s.product_id = m.product_id
	WHERE order_date < join_date
	)
SELECT customer_id
	,product_name
FROM CTE
WHERE rnk = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id
	,COUNT(product_name) AS Total_items
	,SUM(price) AS Total_amount
FROM sales AS s
INNER JOIN members AS mem
	ON s.customer_id = mem.customer_id
INNER JOIN menu AS m
	ON s.product_id = m.product_id
WHERE order_date < join_date
GROUP BY s.customer_id
ORDER BY s.customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?
SELECT customer_id
	,SUM(CASE 
			WHEN product_name = 'sushi'
				THEN price * 10 * 2
			ELSE price * 10
			END) AS points
FROM menu AS m
INNER JOIN sales AS s
	ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?
SELECT s.customer_id
	,SUM(CASE 
			WHEN order_date BETWEEN mem.join_date
					AND (
							SELECT mem.join_date + INT '6'
							)
				THEN price * 10 * 2
			WHEN product_name = 'sushi'
				THEN price * 10 * 2
			ELSE price * 10
			END) AS points
FROM menu AS m
INNER JOIN sales AS s
	ON s.product_id = m.product_id
INNER JOIN members AS mem
	ON s.customer_id = mem.customer_id
WHERE DATE_TRUNC('month', order_date) = '2021-01-01'
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- BONUS QUESTIONS
-- Join All The Things
SELECT s.customer_id
	,order_date
	,product_name
	,price
	,CASE 
		WHEN join_date IS NULL
			THEN 'N'
		WHEN order_date < join_date
			THEN 'N'
		ELSE 'Y'
		END AS member
FROM sales AS s
INNER JOIN menu m
	ON s.product_id = m.product_id
LEFT JOIN members mem
	ON mem.customer_id = s.customer_id
ORDER BY s.customer_id
	,order_date
	,price DESC
	
-- Rank All the Things
WITH CTE AS (
		SELECT s.customer_id
			,order_date
			,product_name
			,price
			,CASE 
				WHEN join_date IS NULL
					THEN 'N'
				WHEN order_date < join_date
					THEN 'N'
				ELSE 'Y'
				END AS member
		FROM sales AS s
		INNER JOIN menu m
			ON s.product_id = m.product_id
		LEFT JOIN members mem
			ON mem.customer_id = s.customer_id
		ORDER BY s.customer_id
			,order_date
			,price DESC
		)

SELECT *
	,CASE 
		WHEN member = 'N'
			THEN NULL
		ELSE RANK() OVER (
				PARTITION BY customer_id
				,member ORDER BY order_date
				)
		END AS ranking
FROM CTE;
