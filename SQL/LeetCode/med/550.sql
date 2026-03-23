/* ***************************************
 * 첫 로그인 후 바로 들어온 걸 파악해야 함
 * 1. 문제 똑바로 읽기: 첫 로그인 후 바로 다음날
 * 2. 처음 이 후 라는 문제 유형에서는
    - row_number()로 첫 날 구분자 가져오기
    - lead를 써서 앞에 있는 날 불러오기
 */
with base as (
    select
        player_id,
        datediff(            
            coalesce(
                lead(event_date) over (
                    partition by player_id
                    order by event_date
                ), date '9999-12-31')
            , event_date
        ) as diff_dd,
        row_number() over (
            partition by player_id
            order by event_date
        ) as rn
      from Activity
),
raw as (
    select
      player_id,
      diff_dd
      from base
     where rn = 1
)
select
   coalesce(
        round(
            1.0 * sum(case when diff_dd = 1 then 1 end)
            / count(*)
        , 2)
    , 0) as fraction
from base
where rn = 1