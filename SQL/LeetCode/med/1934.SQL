# Write your MySQL query statement below
WITH USER_CONFIRM_BASE AS (
    SELECT
        S.USER_ID,
        C.TIME_STAMP,
        C.ACTION
      FROM SIGNUPS S
      LEFT JOIN CONFIRMATIONS C
        ON S.USER_ID = C.USER_ID
)
SELECT
    USER_ID,
    ROUND(
        COUNT(CASE WHEN LOWER(TRIM(ACTION)) = 'confirmed' THEN TIME_STAMP ELSE NULL END)
        / NULLIF(COUNT(*), 0)
    , 2) AS CONFIRMATION_RATE
  FROM USER_CONFIRM_BASE
 GROUP BY USER_ID

/* ======================== 한 번 더 풀이 ============================= */

 with base as (
    select
        s.user_id,
        c.time_stamp,
        c.action
      from signups s
      left
      join Confirmations c
        on s.user_id = c.user_id
)
select
    user_id,
    round(
        sum(case when action = 'confirmed' then 1 else 0 end) * 1.0
        / count(*)
    , 2) as confirmation_rate
  from base
 group by user_id