with base as (
    select count(*) as tl
      from seat
),
even_student as (
select
    id - 1 as id,
    student
  from seat
 where id % 2 = 0
),
odd_student as (
select
    case when s.id = b.tl then id
         else s.id + 1
    end as id,
    s.student
  from seat s
 cross
  join base b
    on 1=1
 where id % 2 = 1
),
union_table as (
select *
  from even_student
union all
select *
  from odd_student
)
select
    *
  from union_table
 order by id