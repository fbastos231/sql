-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

-- CROSS JOIN

-- Creating temp table with vendor_inventory including product and vendor names

DROP TABLE IF EXISTS temp.vendor_inventory_names;
CREATE TEMP TABLE vendor_inventory_names AS

SELECT vendor_name, product_name, (quantity*0)+5 as quantity, original_price --making quantity of all product = 5
FROM vendor_inventory as vi
LEFT JOIN vendor as v -- joining vendor_inventory with vendor to get vendor_name
ON vi.vendor_id = v.vendor_id
LEFT JOIN product as p
ON vi.product_id = p.product_id -- joining vendor_inventory with product to get product_name
GROUP BY vi.vendor_id,vi.product_id
ORDER BY vi.vendor_id,vi.product_id

-- CROSS JOINING temp table created above with customer ids then sum quantity*original_price

SELECT vendor_name, product_name, SUM( quantity*original_price) as sale
FROM vendor_inventory_names
CROSS JOIN (
	SELECT customer_id
	FROM customer
	)
GROUP BY vendor_name, product_name
ORDER BY vendor_name, product_name

SELECT DISTINCT vendor_id, product_id
FROM vendor_inventory
	

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS temp.product_units;
CREATE TEMP TABLE product_units AS
SELECT *, datetime('now') as snapshot_timestamp -- add snapshot_timestamp column
FROM product
WHERE instr(product_qty_type,'unit') > 0 -- only select rows that have the word unit in product_qty_type


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units (product_id, product_name,product_size, product_category_id, product_qty_type, snapshot_timestamp)
VALUES(24,'Pinto Beans', '1 lb', '1','lbs', datetime('now') )  -- similar to previous QUERY add snapshot_timestamp

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE
FROM product_units
WHERE product_id=24

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units
ADD current_quantity INT;		

UPDATE product_units
SET current_quantity = COALESCE(quantity,0) -- REPLACE NULLS with 0s
FROM product_units as pu
LEFT JOIN ( --join product_units with last_quantity QUERY
			SELECT product_id, quantity
			FROM  (
				SELECT *,
				DENSE_RANK() OVER( -- rank market_date with latest date being #1
				PARTITION BY  vendor_id
				ORDER BY market_date DESC) AS ranked
				FROM vendor_inventory
			)
			WHERE ranked = 1
		)  as lq
		ON pu.product_id = lq.product_id
WHERE product_units.product_id = pu. product_id


