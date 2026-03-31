# Write your MySQL query statement belo
select
    sell_date,
    count(distinct product) as num_sold,
    GROUP_CONCAT(DISTINCT product ORDER BY product SEPARATOR ',') AS products
  from activities
 group by sell_date
 order by sell_date