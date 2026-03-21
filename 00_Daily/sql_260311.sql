select
  count(order_id) as total_orders,
  sum(total_amount) as total_revenue,
  AVG(total amount) as average_order_value

from orders
where status = 'completed';

--------------------
SELECT 
    p.category,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_sales
FROM orders o
JOIN products p ON o.product_id = p.id
GROUP BY p.category
ORDER BY total_sales DESC;
--------------------

SELECT 
    DATE_TRUNC('month', order_date) AS order_month,
    SUM(total_amount) AS monthly_revenue,
    COUNT(DISTINCT user_id) AS unique_buyers
FROM orders
GROUP BY 1
ORDER BY 1;

-----------------

SELECT 
    user_id,
    COUNT(order_id) AS purchase_count,
    SUM(total_amount) AS lifetime_value
FROM orders
GROUP BY user_id
HAVING SUM(total_amount) >= 1000000 -- 100만원 이상 구매자 필터링
ORDER BY lifetime_value DESC;

---------------
SELECT 
    CASE 
        WHEN age < 20 THEN '10s'
        WHEN age < 30 THEN '20s'
        WHEN age < 40 THEN '30s'
        ELSE '40s+' 
    END AS age_group,
    COUNT(*) AS user_count
FROM users
GROUP BY 1
ORDER BY 1;

--------------
SELECT *
FROM (
    SELECT 
        category,
        product_name,
        SUM(quantity) AS total_sold,
        RANK() OVER (PARTITION BY category ORDER BY SUM(quantity) DESC) as ranking
    FROM orders o
    JOIN products p ON o.product_id = p.id
    GROUP BY category, product_name
) t
WHERE ranking <= 3;
