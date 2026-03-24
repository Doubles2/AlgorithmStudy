# Write your MySQL query statement below
/* single number: 딱 한 번만 등장하는 숫자 */
select
    max(num) as num
  from (
    select
        num,
        count(*)
      from mynumbers
     group by num
     having count(*) = 1
  ) t
