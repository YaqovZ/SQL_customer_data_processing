SELECT 'Customers' AS table_name, 
       13 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Customers
  
UNION ALL

SELECT 'Products' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Products

UNION ALL

SELECT 'ProductLines' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM ProductLines

UNION ALL

SELECT 'Orders' AS table_name, 
       7 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Orders

UNION ALL

SELECT 'OrderDetails' AS table_name, 
       5 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM OrderDetails

UNION ALL

SELECT 'Payments' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Payments

UNION ALL

SELECT 'Employees' AS table_name, 
       8 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Employees

UNION ALL

SELECT 'Offices' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Offices;

  -- low stock products
  SELECT 
    p.productCode, 
    ROUND(SUM(od.quantityOrdered) * 1.000 / p.quantityInStock, 2) AS lowstock 
FROM 
    products p 
JOIN 
    orderdetails od 
ON 
    p.productCode = od.productCode 
GROUP BY 
    p.productCode 
ORDER BY 
    lowstock DESC 
LIMIT 10;

-- top product performance as in toal sales
SELECT 
    productCode, 
    ROUND(SUM(quantityOrdered * priceEach), 2) AS sum_sales
FROM 
    orderdetails 
GROUP BY 
    productCode 
ORDER BY 
    sum_sales DESC
LIMIT 10;
-- Question 1: Which Products Should We Order More of or Less of?
-- priority products that have low stock and high performances
with low_stock as(
  SELECT 
    p.productCode, 
    ROUND(SUM(od.quantityOrdered) * 1.000 / p.quantityInStock, 2) AS lowstock 
FROM 
    products p 
JOIN 
    orderdetails od 
ON 
    p.productCode = od.productCode 
GROUP BY 
    p.productCode 
ORDER BY 
    lowstock DESC 
LIMIT 10
)
SELECT 
    od.productCode, p.productName, p.productLine,
    ROUND(SUM(quantityOrdered * priceEach), 2) AS sum_sales
FROM 
    orderdetails od
JOIN 
    products p 
ON 
    p.productCode = od.productCode 
WHERE
    od.productCode in (SELECT productCode FROM low_stock)
GROUP BY 
    od.productCode 
ORDER BY 
    sum_sales DESC
LIMIT 10;
    
 -- Question 2: How Should We Match Marketing and Communication Strategies to Customer Behavior?
-- find the profit each customer provided
SELECT o.customerNumber,
       SUM(quantityOrdered * (priceEach - buyPrice)) AS profit_per_customer
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
JOIN orders o ON od.orderNumber = o.orderNumber
GROUP BY o.customerNumber;

-- find the 5 important clients
WITH profit_per_customer_table AS (
  SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od ON p.productCode = od.productCode
  JOIN orders o ON o.orderNumber = od.orderNumber
  GROUP BY o.customerNumber
)
SELECT c.contactLastName, c.contactFirstName, c.city, c.country, ROUND(ppc.profit, 2) AS profit
FROM profit_per_customer_table ppc
JOIN customers c ON ppc.customerNumber = c.customerNumber
ORDER BY profit DESC
LIMIT 5;

-- find the 5 least engaged clients
WITH profit_per_customer_table AS (
  SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od ON p.productCode = od.productCode
  JOIN orders o ON o.orderNumber = od.orderNumber
  GROUP BY o.customerNumber
)
SELECT c.contactLastName, c.contactFirstName, c.city, c.country, ROUND(ppc.profit, 2) AS profit
FROM profit_per_customer_table ppc
JOIN customers c ON ppc.customerNumber = c.customerNumber
ORDER BY profit 
LIMIT 5;
-- Question 3: How Much Can We Spend on Acquiring New Customers?
-- the LTV per customer
with profit_per_customer_table as
(SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber)
 
SELECT AVG(profit) as LTV
  FROM profit_per_customer_table;
  
 -- Find the proportion of new customers each month
 WITH 

payment_with_year_month_table AS (
SELECT *, 
       CAST(SUBSTR(paymentDate, 1,4) AS INTEGER)*100 + CAST(SUBSTR(paymentDate, 6,7) AS INTEGER) AS year_month
  FROM payments p
),

customers_by_month_table AS (
SELECT p1.year_month, COUNT(*) AS number_of_customers, SUM(p1.amount) AS total
  FROM payment_with_year_month_table p1
 GROUP BY p1.year_month
),

new_customers_by_month_table AS (
SELECT p1.year_month, 
       COUNT(*) AS number_of_new_customers,
       SUM(p1.amount) AS new_customer_total,
       (SELECT number_of_customers
          FROM customers_by_month_table c
        WHERE c.year_month = p1.year_month) AS number_of_customers,
       (SELECT total
          FROM customers_by_month_table c
         WHERE c.year_month = p1.year_month) AS total
  FROM payment_with_year_month_table p1
 WHERE p1.customerNumber NOT IN (SELECT customerNumber
                                   FROM payment_with_year_month_table p2
                                  WHERE p2.year_month < p1.year_month)
-- this selects the customers, within each month, that are not among the customers that have a history of purchase
-- it means the new customers are filtered in for the main query
 GROUP BY p1.year_month
)

SELECT year_month, 
       ROUND(number_of_new_customers*100/number_of_customers,1) AS number_of_new_customers_props,
       ROUND(new_customer_total*100/total,1) AS new_customers_total_props
  FROM new_customers_by_month_table;
  
 /* Project Summary

Inventory Management:
- Focus on restocking classic cars, including specific models like 1952 Alpine Renault 1300, 1968 Ford Mustang, etc.
- These products show high sales performance and are crucial for our inventory.

Marketing Strategies:
- VIP customers like Diego Freyre and Susan Nelson contribute significantly to profits.
- Tailored marketing strategies are recommended for VIPs to maintain loyalty.
- Least engaged customers, including Mary Young and Leslie Taylor, offer potential for increased engagement.
- Targeted marketing could transform them into more profitable customers.

Customer Acquisition Budget:
- LTV analysis suggests an average profit of $39,039.59 per customer.
- This figure guides our budget for new customer acquisition strategies.

*/

