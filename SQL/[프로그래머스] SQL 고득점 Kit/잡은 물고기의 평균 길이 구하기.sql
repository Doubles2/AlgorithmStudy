-- 코드를 작성해주세요
with base as (
    select
        id,
        coalesce(length, 10) as length
      from fish_info        
)
select
    round(avg(length), 2) as average_length
from base

/* 이렇게 하지 말고 sum / count 해야할 거 같은데 통과를 하니 찝찝함 */