

  -- 1. What is the total amount each customer spent at the restaurant?
  
  with cte as (select customer_id,count(product_id)*price as pric
  from sales join menu 
  using(product_id)
  group by customer_id,product_id)
  select customer_id,sum(pric) as amount
  from cte
  group by customer_id;
  
  select customer_id,sum(price) as amount
  from sales join menu
  using(product_id)
  group by customer_id;
  
 /* RESULT
| customer |    amount    |
| -------- | ------------ |
| B        | 74           |
| C        | 36           |
| A        | 76           |
*/

-- 2. How many days has each customer visited the restaurant?

select customer_id,count(distinct order_date) as visits
from sales
group by customer_id;

/* RESULT
| customer | visits |
| -------- | ------ |
| B        | 6      |
| A        | 4      |
| C        | 2      |
*/

-- 3. What was the first item from the menu purchased by each customer?

with cte as (select customer_id,product_name,dense_rank()over(partition by customer_id order by order_date)as r
from sales join menu 
using(product_id))
select customer_id,product_name
from cte
where r=1;

/*RESULT
| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| A           | sushi        |
| B           | curry        |
| C           | ramen        |
| C           | ramen        |
*/

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select product_name,count(product_id) as count
from menu join sales
using(product_id)
group by product_name
order by count desc
limit 1;

/* RESULT
| product_name | count |
| ------------ | ----- |
| ramen        | 8     |
*/

-- 5. Which item was the most popular for each customer?
with cte as (select customer_id,product_name,rank()over(partition by customer_id order by c desc) as r
from (select customer_id,product_name,count(product_id) as c
from menu join sales
using(product_id)
group by customer_id,product_name)a)
select customer_id, product_name
from cte
where r = 1;

/* RESULT
| customer_id | product_name |
| ----------- | ------------ |
| A           | ramen        |
| B           | curry        |
| B           | sushi        |
| B           | ramen        |
| C           | ramen        |
*/
-- 6. Which item was purchased first by the customer after they became a member?

select customer_id,product_name
from (select customer_id,product_name,dense_rank()over(partition by customer_id order by order_date) as r
from members join sales
using(customer_id)
join menu 
using (product_id)
where order_date>= join_date) a
where r = 1;

/* RESULT
| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| B           | sushi        |
*/

-- 7. Which item was purchased just before the customer became a member?
select customer_id,product_name
from (select customer_id,product_name,dense_rank() over(partition by customer_id order by order_date desc) as r
from members join sales 
using(customer_id)
join menu 
using(product_id)
where order_date < join_date
group by customer_id,product_id) a
where r = 1;

/*RESULT
| customer_id | product_name |
| ----------- | ------------ |
| A           | sushi        |
| A           | curry        |
| B           | sushi        |
*/

-- 8. What is the total items and amount spent for each member before they became a member?
select customer_id,total_items,sum(amount) as amount
from (select a.customer_id,
count(product_id) as total_items,
sum(price) as amount
from sales a join menu
using(product_id)
join members 
using(customer_id)
where a.order_date < join_date
group by customer_id)a
group by customer_id;

with cte as (select customer_id,count(product_id) total_items,product_name, count(product_id)* price as amount
from sales join members
using(customer_id)
join menu 
using(product_id)
where order_date < join_date
group by customer_id,product_id)
select customer_id,sum(total_items),sum(amount) as total_amount
from cte
group by customer_id;

/*RESULT
| customer | total_product | total_spent |
| -------- | ------------- | ----------- |
| A        | 2             | 25          |
| B        | 3             | 40          |
*/

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id,sum(credit_points) AS credit_points
from 
(select customer_id, case
when product_name = 'sushi' then count(product_id)*price *2*10 
else  count(product_id)*price *10 
end as credit_points
from sales join menu 
using(product_id)
group by customer_id,product_id) a
group by customer_id;

/*RESULT
| customer_id | credit_points |
| ----------- | ------------- |
| A           |     860       |
| B           |     940       |
| C           |     360       |
*/


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select customer_id,sum(credit_points) as credit_points
from (select customer_id, case
when order_date < date_add(join_date, interval 8 day) then count(product_id)*price*2*10 
when product_name ='sushi' then count(product_id)*price*2*10 
else count(product_id)*price*10 
end as credit_points 
from sales join menu 
using(product_id)
join members 
using(customer_id)
where order_date >= join_date and  month(order_date) < 02
group by customer_id,product_id) a
group by customer_id;
/* RESULT
| customer_id | credit_points  |
| ----------- | -------------  |
| B           |      440       |
| A           |      1020      |
*/

-- BONUS QUESTION -1
select customer_id,order_date,product_name,price,
case 
when order_date >= join_date then 'Y'
else 'N'
end as 'member'
from sales join menu 
using(product_id)
join members
using(customer_id)
order by customer_id,order_date;

/* RESULT
| customer_id | order_date               | product_name | price | member |
| ----------- | ------------------------ | ------------ | ----- | ------ |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | N      |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | Y      |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | Y      |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | N      |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | N      |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | Y      |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | Y      |
| B           | 2021-02-01T00:00:00.000Z | ramen        | 12    | Y      |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |
| C           | 2021-01-07T00:00:00.000Z | ramen        | 12    | N      |
*/

-- BONUS QUESTION 2
select *,case 
when member = 'Y' then dense_rank() over(partition by customer_id,member order by order_date)
else null
end as ranking
from (
select customer_id,order_date,product_name,price,
case when order_date >= join_date then 'Y'
else 'N'
end as member
from sales join menu 
using (product_id)
left join members 
using(customer_id)
order by customer_id,order_date)a;

/* RESULT
| customer_id | order_date               | product_name | price | member | ranking |
| ----------- | ------------------------ | ------------ | ----- | ------ | ------- |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | N      |         |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |         |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | Y      | 1       |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |         |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | N      |         |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | N      |         |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | Y      | 1       |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | Y      | 1       |
| C           | 2021-01-07T00:00:00.000Z | ramen        | 12    | Y      | 3       |
*/
