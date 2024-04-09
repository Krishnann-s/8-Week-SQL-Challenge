-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, 
-- write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
SELECT p.plan_id
	,s.customer_id
	,p.plan_name
	,p.price
	,s.start_date
FROM plans AS p
INNER JOIN subscriptions AS s
	ON p.plan_id = s.plan_id
WHERE s.customer_id <= 8
	-- Customer id 1 Starts a free trial on 2020-08-01 and post his free trial, which is for 1 week, he upgrades his plan to “basic monthly” starting 2020-08-08 for $9.90.
	-- Customer id 2 Starts a free trial on 2020-09-20 and later upgrades to “pro annual” plan which costs $199.
	-- Customer id 4 Starts a free trial on 2020-01-17 and upgrades to “basic monthly” plan on 2020-01-24 and then churns his plan on 2020-04-21.
