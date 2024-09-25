-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

--ANSWER:
--In this database all the names are present but that could not be the case for other so I added a coalesce statement to product name as well

SELECT 
  COALESCE(product_name, 'missing') || ', ' ||  COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')' AS product_description
FROM product

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

--ANSWER :

SELECT customer_id,market_date,
DENSE_RANK() OVER(
PARTITION BY  customer_id
ORDER BY customer_id ASC, market_date ASC) AS customer_visit_number
FROM customer_purchases
GROUP BY customer_id,market_date
ORDER BY customer_id,market_date

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

--ANSWER:

SELECT customer_id, market_date
FROM(
	SELECT customer_id,market_date,
	DENSE_RANK() OVER(
	PARTITION BY  customer_id
	ORDER BY customer_id ASC, market_date DESC) AS customer_visit_number
	FROM customer_purchases
	GROUP BY customer_id,market_date
	ORDER BY customer_id,market_date DESC) AS cv

WHERE cv.customer_visit_number = 1

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

--ANSWER :

SELECT *,
COUNT() OVER(
PARTITION BY customer_id, product_id) AS cp_count
FROM customer_purchases
ORDER BY customer_id, product_id


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

--ANSWER:

SELECT p.product_id, p.product_name, p.product_size, p.product_category_id, p.product_qty_type, d.description
FROM product as p
LEFT JOIN
	(
		SELECT *, LTRIM(RTRIM(SUBSTR(product_name,  INSTR(product_name, '-')+1))) AS description
		FROM product
		WHERE  INSTR(product_name, '-') > 0
	) AS d
ON p.product_id = d.product_id

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

--ANSWER:

SELECT *
FROM product
WHERE product_size REGEXP '[0-9]+'


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

--ANSWER:


WITH market_daily_sales AS (
SELECT *, SUM(cost_to_customer_per_qty*quantity) AS total_sale
FROM customer_purchases
GROUP BY market_date
ORDER BY market_date ASC
)

SELECT market_date, total_sale,'best' AS 'rank'
FROM  (
	SELECT *,
	RANK() OVER(
	ORDER BY total_sale DESC) AS rank_
	FROM market_daily_sales
) AS ranked_mds
WHERE rank_ = 1 

UNION
SELECT *
FROM(

WITH market_daily_sales AS (
SELECT *, SUM(cost_to_customer_per_qty*quantity) AS total_sale
FROM customer_purchases
GROUP BY market_date
ORDER BY market_date ASC
)

SELECT market_date, total_sale,'worst' AS 'rank'
FROM  (
	SELECT *,
	RANK() OVER(
	ORDER BY total_sale ASC) AS rank_
	FROM market_daily_sales
) AS ranked_mds
WHERE rank_ = 1 
)
