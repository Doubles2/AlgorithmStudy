# Write your MySQL query statement below
WITH BASE_FIRST_ORDER AS (
    SELECT
        D.CUSTOMER_ID,
        D.ORDER_DATE,
        D.CUSTOMER_PREF_DELIVERY_DATE
      FROM (
        SELECT
            CUSTOMER_ID,
            ORDER_DATE,
            CUSTOMER_PREF_DELIVERY_DATE,
            ROW_NUMBER() OVER (
                PARTITION BY CUSTOMER_ID
                ORDER BY ORDER_DATE
            ) AS RN
          FROM DELIVERY
      ) D
     WHERE D.RN = 1
),
IMD_SCHED_RAW AS (
    SELECT
        CUSTOMER_ID,
        CASE WHEN ORDER_DATE = CUSTOMER_PREF_DELIVERY_DATE THEN 'immediate'
             ELSE 'scheduled'
        END AS IMMEDIATE_YN
      FROM BASE_FIRST_ORDER
)
SELECT
    ROUND(
        COUNT(CASE WHEN IMMEDIATE_YN = 'immediate' THEN CUSTOMER_ID ELSE NULL END)
        / NULLIF(COUNT(CUSTOMER_ID), 0)
        * 100
    , 2) AS immediate_percentage
  FROM IMD_SCHED_RAW

  /* ======================== 한 번 더 풀이 ============================= */

  with base as (
    select
        customer_id,
        order_gb
      from (
        select
            customer_id,
            case when order_date = customer_pref_delivery_date then 'immediate'
                else 'scheduled'
            end as order_gb,
            row_number() over (
                partition by customer_id
                order by order_date
            ) as rn
        from delivery
      ) t
     where rn = 1    
)
select
    round(
        sum(case when order_gb = 'immediate' then 1 else 0 end) * 100.0
        / count(*)
    , 2) as immediate_percentage
  from base