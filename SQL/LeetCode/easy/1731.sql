with base as (
    select 
        reports_to as id,
        count(*) as cnt,
        round(avg(1.0 * age)) as avg_age
      from Employees
     where reports_to is not null
     group by reports_to
)
select
    e.employee_id,
    e.name,
    b.cnt as reports_count,
    b.avg_age as average_age
  from employees e
  join base b
    on e.employee_id = b.id
 order by e.employee_id