with base as (
    select
        'Low Salary' as category
    union all
    select
        'Average Salary' as category
    union all
    select
        'High Salary' as category
),
base_account as (
    select 
        account_id,
        case when income < 20000 then 'Low Salary'
             when income >= 20000 and income <= 50000 then 'Average Salary'
             else 'High Salary'
        end as category
      from Accounts
)
select
    b.category,
    coalesce(count(ba.account_id), 0) as accounts_count
  from base b
  left
  join base_account ba
    on b.category = ba.category
 group by b.category