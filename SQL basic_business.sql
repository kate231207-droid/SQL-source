--1. call data from table 
select *
from PRODUCTS;


--. call specfic colimn data from table 
select PRODUCT_CODE, PRODUCT_NAME, LIST_PRICE, DISCOUNT_PERCENT
from PRODUCTS;

--. order by desc
select PRODUCT_CODE, PRODUCT_NAME, LIST_PRICE, DISCOUNT_PERCENT
from PRODUCTS
order by LIST_PRICE desc;

--2. join name ||--> string concatenation operator
select *
from customers;

select  LAST_NAME || ',' || FIRST_NAME AS FULL_NAME
from CUSTOMERS
WHERE LAST_NAME LIKE 'E%'
OR LAST_NAME LIKE 'F%'
OR LAST_NAME LIKE 'G%'
ORDER BY LAST_NAME ASC;

--3. select products with where and order by quary
select product_name, list_price, date_added
from products
where list_price >= 500 
and list_price <=2000
and category_id =1 
order by date_added DESC;


--4. select products with where and order by quary
-- part A: 
select product_name, list_price, date_added
from products
where list_price between 500 and 2000
and category_id =1 
order by date_added DESC;

--part B:
select product_name, list_price, date_added
from products
where list_price >= 500 
and list_price <=2000
and category_id =1 

minus

select product_name, list_price, date_added
from products
where list_price between 500 and 2000
and category_id =1 
order by date_added DESC;

--5. return column name and data definition with round 
select product_name, list_price, discount_percent, 
round(LIST_PRICE*(DISCOUNT_PERCENT/100),2) as discount_amount,
round(LIST_PRICE-(list_price*(DISCOUNT_PERCENT /100)),2) AS discount_price
from products
order by discount_price DESC;

--6. Make a copy of the previous query and add a row filter : where -> aliance x
select product_name, list_price, discount_percent, 
round(LIST_PRICE*(DISCOUNT_PERCENT/100),2) as discount_amount,
round(LIST_PRICE-(list_price*(DISCOUNT_PERCENT /100)),2) AS discount_price
from products
where round(list_price*(discount_percent / 100),2) >200
order by discount_price DESC
fetch first 3 rows only;

--7. Return only the rows where the ship_date column contains a null value.
-- SELECT → FROM → WHERE → ORDER BY
select order_id, customer_id, order_date, ship_date
from orders
where ship_date is null
order by 3 desc;


--8. FROM clause that specifies the dual table -> calculation practice
select 100 as price,
.0825 AS tax_rate,
100 * .0825 AS tax_amount,
100 + (100 * .0825) AS total
FROM dual;

--9. Simple join 2
select c.category_name, p.product_name, p.list_price
from Categories c
Join Products p on c.category_id = p.category_id
order by product_name ASC, p.product_name ASC;

--10. simple join 2
select c.customer_id, c.first_name, c.last_name, A.line1, A.city, A.state, A. zip_code
from customers c
Join ADDRESSES A on c.customer_id = A.customer_id
where c.email_address = 'allan.sherwood@yahoo.com';


--11. simple join 3
select c.customer_id, c.first_name, c.last_name, A.line1, A.city, A.state, A. zip_code
from customers c
Join ADDRESSES A on c.shipping_address_id = A.address_id;

--- 12. multiple join using table aliases /  sort -> order by
select c.last_name, c.first_name, o.order_date, p.product_name, oi.item_price, oi.discount_amount, oi.quantity
from customers c
join orders o on c.customer_id = o.CUSTOMER_ID
join ORDER_ITEMS oi on oi.order_id = o.order_id
join products p on oi.product_id = p.PRODUCT_ID
order by c.last_name, o.order_date, p.product_name;


---13. contact list creation not ordered to send email campaign.
select c.last_name, c.first_name, c.email_freq
from Customers c
left join orders o on c.customer_id= o.CUSTOMER_ID
where o.ORDER_ID is null;

--14. full outer join
SELECT c.customer_id, 
       c.last_name, 
       c.email_address, 
       ec.freq_id, 
       ec.freq_description
FROM CUSTOMERS c
FULL OUTER JOIN EMAIL_CAMPAIGN ec ON c.email_freq = ec.freq_id
WHERE c.email_freq IS NULL  -- 캠페인에 가입 안 한 고객
   OR ec.freq_id IS NULL    -- 가입자가 한 명도 없는 캠페인
ORDER BY ec.freq_id ASC, c.customer_id ASC;
