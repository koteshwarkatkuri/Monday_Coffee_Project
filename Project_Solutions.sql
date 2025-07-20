-- Monday Coffee -- Data Analysis
select * from city;
select * from products;
select * from customers;
select * from sales;

-- Reports & Data Analysis
--Q1.How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT city_name,
	   ROUND((population * 0.25)/1000000,2) AS coffee_consumers_in_millions,
       city_rank
FROM city
ORDER BY 2 DESC;

-- Total Revenue from Coffee Sales
--q2. What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT ci.city_name, 
		
		SUM(s.total) AS Total_revenue
FROM sales AS s
JOIN customers AS c
on s.customer_id = c.customer_id
JOIN city AS ci
on ci.city_id = c.city_id
WHERE
	EXTRACT(YEAR FROM s.sale_date) = 2023
	AND
	EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;

-- Sales Count for Each Product
-- Q3.How many units of each coffee product have been sold?
SELECT p.product_name,
	   COUNT(s.sale_id) AS Total_orders FROM products as p
JOIN sales as s
ON p.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Average Sales Amount per City
-- Q4. What is the average sales amount per customer in each city?
 SELECT ci.city_name,
 		SUM(s.total) AS total_revenue,
 		COUNT(DISTINCT S.customer_id) AS total_cx,
		 ROUND(SUM(s.total)::numeric/COUNT(DISTINCT S.customer_id)::numeric,2) AS avg_sale_pr_cx
 FROM sales AS s
 JOIN customers AS c
 ON s.customer_id = c.customer_id
 JOIN city AS ci
 ON  c.city_id = ci.city_id
 GROUP BY 1
 ORDER BY 2 DESC;

--city Population and Coffee Consumers (25%)
-- Q5. Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table AS
(SELECT city_name ,
		ROUND((population * 0.25)/1000000,2) AS coffee_consumers
FROM city),
customer_table
AS
(SELECT ci.city_name,
		COUNT(DISTINCT c.customer_id) AS unique_cx
FROM sales AS s
JOIN
customers AS C
ON c.customer_id = s.customer_id
JOIN
city AS ci
ON ci.city_id = c.city_id
GROUP BY 1)

SELECT
		customer_table.city_name,
		city_table.coffee_consumers,
		customer_table.unique_cx
FROM
city_table 
LEFT JOIN
customer_table
ON city_table.city_name = customer_table.city_name;

-- Top Selling Products by City
--Q.6 What are the top 3 selling products in each city based on sales volume?

SELECT * FROM
(SELECT ci.city_name,
		p.product_name,
		COUNT(s.sale_id) AS Total_orders,
		DENSE_RANK () OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS Rank
FROM sales AS s
JOIN products AS p
ON s.product_id = p.product_id
JOIN
customers AS c
ON c.customer_id = s.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
GROUP BY 1,2) AS t1
WHERE Rank <=3;

-- Customer Segmentation by City
-- Q7.How many unique customers are there in each city who have purchased coffee products?

SELECT * FROM products;
SELECT ci.city_name,
		COUNT(DISTINCT c.customer_id) AS unique_cx
FROM city AS ci
LEFT JOIN
customers AS C
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE
	 s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1;	 

-- Average Sale vs Rent
--Q8. Find each city and their average sale per customer and avg rent per customer

-- Conclusions

WITH city_table
AS
(SELECT ci.city_name,
SUM(s.total) AS total_revenue,
COUNT(DISTINCT s.customer_id) AS total_cx,
ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) AS avg_sale_per_cx 
FROM sales as s
JOIN
customers AS c
ON s.customer_id = c.customer_id
JOIN
city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),
city_rent
AS
(
SELECT 
	  city_name,
	  estimated_rent
FROM city
)
SELECT 
	 cr.city_name,
	 cr.estimated_rent,
	 ct.total_cx,
	 ct.avg_sale_per_cx,
	 ROUND(
			cr.estimated_rent::numeric/ct.total_cx::numeric,2) 
			AS avg_rent_per_cx
	FROM city_table AS ct
	JOIN city_rent AS cr
	ON cr.city_name = ct.city_name
	ORDER BY 4 DESC;

-- Monthly Sales Growth
-- Q9. Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city		

WiTH 
monthly_sales
AS
(SELECT ci.city_name,
		EXTRACT(MONTH FROM sale_date) AS month,
		EXTRACT(YEAR FROM sale_date) AS year,
		SUM(s.total) AS total_sale
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1,2,3
ORDER BY 1,3,2
),
growth_ratio
AS
(
SELECT city_name,
		month,
		year,
		total_sale AS cr_month_sale,
		LAG(total_sale,1) OVER(PARTITION BY city_name ORDER BY year,month) AS last_month_sale
FROM monthly_sales
)
SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND
	(
	(cr_month_sale - last_month_sale)::numeric/last_month_sale::numeric * 100
	,2)
	AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL ;

-- Market Potential Analysis
-- Q10. Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table
AS
(SELECT ci.city_name,
SUM(s.total) AS total_revenue,
COUNT(DISTINCT s.customer_id) AS total_cx,
ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) AS avg_sale_per_cx 
FROM sales as s
JOIN
customers AS c
ON s.customer_id = c.customer_id
JOIN
city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),
city_rent
AS
(
SELECT 
	  city_name,
	  estimated_rent,
	  ROUND((population * 0.25)/1000000 ,3) AS estimated_coffee_consumer_in_millions
FROM city
)
SELECT 
	 cr.city_name,
	 total_revenue,
	 cr.estimated_rent,
	 ct.total_cx,
	 estimated_coffee_consumer_in_millions,
	 ct.avg_sale_per_cx,
	 ROUND(
			cr.estimated_rent::numeric/ct.total_cx::numeric,2) 
			AS avg_rent_per_cx
	FROM city_table AS ct
	JOIN city_rent AS cr
	ON cr.city_name = ct.city_name
	ORDER BY 2 DESC;

/*
--Recommendation
City 1: Pune
		1. Avg rent per customer is very less.
		2. highest total revenue.
		3. avg_sale_per customer is also high.

City 2: Delhi
		1. Highest estimated coffee consumers which is 7.7 Million.
		2. Highest total number of customers, which is 68.
		3. avg rent per customer 330 (still under 500).

City 3: Jaipur
		1. Highest number of customers, which is 69.
		2. avg rent per customer is very less i.e 156.
		3. avg sale per customer is better which at 11.6k.

	
