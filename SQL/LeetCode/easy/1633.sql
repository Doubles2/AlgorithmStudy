# Write your MySQL query statement below
with base as (
    select
        u.user_id,
        r.contest_id
      from users u
     cross
      join register r
        on 1=1
),
raw as (
    select
        b.contest_id,
        b.user_id,
        r.user_id as reg_user_id
      from base b
      left
      join register r
        on b.contest_id = r.contest_id
       and b.user_id = r.user_id
)
select
    contest_id,
    round(
        100.0 * sum(case when reg_user_id is not null then 1 end)
        / count(user_id)
    , 2) as percentage
  from raw
 group by contest_id
 order by 2 desc, 1