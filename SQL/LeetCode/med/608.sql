# Write your MySQL query statement below
with base as (
    select
        p_id,
        count(*) as cnt
      from Tree
     where p_id is not null
     group by p_id
),
raw as (
    select
        t.id,
        t.p_id,
        coalesce(b.cnt, 0) as cnt
      from Tree t
      left
      join base b
        on t.id = b.p_id
)
select
    id,
    case when p_id is null then "Root"
         when cnt > 0 then "Inner"
         else "Leaf"
    end as type
  from raw