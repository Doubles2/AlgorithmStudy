# 최초로 한 번에 통과한 med 난이도 문제
with base_r as (
    select
        requester_id as id,
        count(*) as cnt
    from RequestAccepted
    group by requester_id
),
base_a as (
    select
        accepter_id as id,
        count(*) as cnt
    from RequestAccepted
    group by accepter_id
),
raw as (
    select
        id,
        cnt
    from base_r
    union all
    select
        id,
        cnt
    from base_a
),
agg as (
    select 
        id,
        sum(cnt) as cnt,
        row_number() over (
            order by sum(cnt) desc
        ) as rn
    from raw
    group by 1
)
select
    id,
    cnt as num
from agg
where rn = 1