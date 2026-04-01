# Write your MySQL query statement below
with base as (
    select
        person_name,
        row_number() over (
            order by c_sum desc
        ) as rn
    from (
        select
            turn,
            person_id,
            person_name,
            weight,
            sum(weight) over (
                order by turn
            ) as c_sum
        from queue
    ) bs
    where c_sum <= 1000
)
select
    person_name
  from base
 where rn = 1