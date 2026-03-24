# Write your MySQL query statement below
with base as (
    select
        p.project_id,
        e.experience_years
      from project p
      left
      join employee e
        on p.employee_id = e.employee_id
)
select
    project_id,
    round(avg(experience_years), 2) as average_years
  from base
 group by project_id