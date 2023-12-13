CREATE DATABASE credit_card_transaction;


DROP TABLE credit_card_transaction;
-- SQL porfolio project.

USE credit_card_transaction;
SELECT *
FROM credit_card_transaction;
-- solve below questions
-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
with cte as(	
    SELECT city,
	SUM(amount) AS total_spend,
	DENSE_RANK() OVER (ORDER BY SUM(amount) DESC) AS spend_rank
	FROM credit_card_transaction
	GROUP BY city
)
SELECT city,total_spend,
    ROUND((total_spend / SUM(total_spend) OVER ()) * 100, 2) AS percentage
FROM cte
WHERE spend_rank <= 5;

-- 2- write a query to print highest spend month and amount spent in that month for each card type
WITH cte AS (
    SELECT
        card_type,
        YEAR(transaction_date) AS yt,
        MONTH(transaction_date) AS mt,
        SUM(amount) AS total_spend
    FROM credit_card_transaction
    GROUP BY card_type, YEAR(transaction_date), MONTH(transaction_date)
)
SELECT *
FROM (
    SELECT *,
        RANK() OVER (PARTITION BY card_type ORDER BY total_spend DESC) AS rn
    FROM cte
) AS a
WHERE rn = 1;


-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
SELECT *
FROM credit_card_transaction as t
WHERE ( 
     SELECT SUM(amount)
		FROM credit_card_transaction
		WHERE card_type = t.card_type
		AND transaction_id <= t.transaction_id
)>=1000000;
-- doubt

-- 4- write a query to find city which had lowest percentage spend for gold card type
WITH cte AS (
    SELECT city, card_type, SUM(amount) AS total_amount,
           SUM(CASE WHEN card_type = 'Gold' THEN amount END) AS gold_amount
    FROM credit_card_transaction
    GROUP BY city, card_type
)

SELECT city, SUM(gold_amount) * 1.0 / SUM(total_amount) AS gold_ratio
FROM cte
GROUP BY city
HAVING COUNT(gold_amount) > 0 AND SUM(gold_amount) > 0
ORDER BY gold_ratio;

-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte as (
select city,exp_type, sum(amount) as total_amount from credit_card_transaction
group by city,exp_type)
select
city , max(case when rn_asc=1 then exp_type end) as lowest_exp_type
, min(case when rn_desc=1 then exp_type end) as highest_exp_type
from
(select *
,rank() over(partition by city order by total_amount desc) rn_desc
,rank() over(partition by city order by total_amount asc) rn_asc
from cte) A
group by city;
-- 6- write a query to find percentage contribution of spends by females for each expense type
SELECT exp_type,
SUM(CASE WHEN gender= 'F' THEN amount ELSE 0 END)*1.0/SUM(amount) as female_persentage_contribution
FROM credit_card_transaction
GROUP BY exp_type
ORDER BY female_persentage_contribution desc;

-- 7- which card and expense type combination saw highest month over month growth in Jan-2014
WITH cte AS (
    SELECT 
        card_type,
        exp_type,
        YEAR(transaction_date) AS yt,
        MONTH(transaction_date) AS mt,
        SUM(amount) AS total_spend
    FROM credit_card_transaction
    GROUP BY card_type, exp_type, YEAR(transaction_date), MONTH(transaction_date)
)
SELECT *,
       (total_spend - prev_month_spend) AS mom_growth
FROM (
    SELECT *,
           LAG(total_spend, 1) OVER (PARTITION BY card_type, exp_type ORDER BY yt, mt) AS prev_month_spend
    FROM cte
) AS A
WHERE prev_month_spend IS NOT NULL AND yt = 2014 AND mt = 1
ORDER BY mom_growth DESC;

-- 8- during weekends which city has highest total spend to total no of transcations ratio 
SELECT city, SUM(amount) * 1.0 / COUNT(*) AS ratio
FROM credit_card_transaction
WHERE DAYOFWEEK(transaction_date) IN (1, 7)
GROUP BY city
ORDER BY ratio DESC
LIMIT 1;

-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city
WITH cte AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY transaction_date, transaction_id) AS rn
    FROM credit_card_transaction
)

SELECT city,
       DATEDIFF(MAX_date, MIN_date) AS datediff1
FROM (
    SELECT city,
           MAX(CASE WHEN rn = 1 THEN transaction_date END) AS MIN_date,
           MAX(CASE WHEN rn = 500 THEN transaction_date END) AS MAX_date
    FROM cte
    WHERE rn = 1 OR rn = 500
    GROUP BY city
    HAVING COUNT(1) = 2
) subquery
ORDER BY datediff1;
