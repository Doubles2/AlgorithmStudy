/* =======================================================================
  공통 데이터 스키마(문제 1~3 사용)
    1) ab_assignments
        user_id (BIGINT)
        experiment_id (VARCHAR) — 예: 'EATS_EXP_101'
        variant (VARCHAR) — 'control' | 'treatment'
        assigned_at (TIMESTAMP)

    2) users
        user_id (BIGINT)
        signup_ts (TIMESTAMP)
        city (VARCHAR)

    3) orders
        order_id (BIGINT)
        user_id (BIGINT)
        order_ts (TIMESTAMP)
        is_completed (BOOLEAN)
        gmv (DOUBLE) — 주문금액

    4) deliveries
        order_id (BIGINT)
        pickup_zone (VARCHAR)
        actual_mins (INT) — 실제 배달 소요시간(분)
        is_rainy (BOOLEAN)
   ======================================================================= */

/* =======================================================================
    (SQL-1) 일자별 주문 수/매출
   =======================================================================

    orders에서 날짜별(date(order_ts)) completed 주문 수, gmv 합계를 구하세요.

   ======================================================================= */
SELECT
    DATE(ORDER_TS) AS ORDER_DATE,
    COUNT(ORDER_ID) AS CNT_ORDER,
    SUM(GMV) AS SUM_SMV
  FROM ORDERS
 WHERE IS_COMPLETED = TRUE
 GROUP BY DATE(ORDER_TS)

/* =======================================================================
    (SQL-2) 유저별 첫 주문일
   =======================================================================
    
    orders에서 유저별 completed 첫 주문일(min order_ts)을 구하세요.

   ======================================================================= */
SELECT
    USER_ID,
    ORDER_TS AS FIRST_ORDER_TS
  FROM (
    SELECT
        USER_ID,
        ORDER_TS,
        ROW_NUMBER() OVER (
            PARTITION BY USER_ID 
            ORDER BY ORDER_TS
        ) AS RN
    FROM ORDERS
   WHERE 1=1
     AND IS_COMPLETED = TRUE
  )
 WHERE 1=1
   AND RN = 1

/* =======================================================================
    (SQL-3) A/B 배정자 수(중복 제거)
   =======================================================================

    ab_assignments에서 실험 EATS_EXP_101의 variant별 배정 유저 수를 구하되,
    유저당 1번(가장 이른 assigned_at)만 인정하세요.

   ======================================================================= */
SELECT
    VARIANT,
    COUNT(USER_ID) AS CNT_USER
  FROM (
    SELECT 
        USER_ID,
        VARIANT,
        ROW_NUMBER() OVER (
            PARTITION BY EXPERIMENT_ID, USER_ID
            ORDER BY ASSIGNED_AT
        ) AS RN
      FROM ab_assignments
     WHERE EXPERIMENT_ID = 'EATS_EXP_0101'
)
 WHERE RN = 1
 GROUP BY VARIANT
/* =======================================================================
    (SQL-4) “배정 후 7일 이내 주문 경험자” 비율(가드레일 제외)
   =======================================================================

    (SQL-3의 배정자 기준) 배정 후 7일 이내 completed 주문이 1건 이상인 유저 비율을 
    variant별로 구하세요.

   ======================================================================= */
WITH BASE_ASSIGN AS (
    SELECT
        USER_ID,
        VARIANT,
        ASSIGNED_AT
      FROM (
        SELECT 
            USER_ID,
            VARIANT,
            ASSIGNED_AT,
            ROW_NUMBER() OVER (
                PARTITION BY EXPERIMENT_ID, USER_ID
                ORDER BY ASSIGNED_AT
            ) AS RN
          FROM AB_ASSIGNMENTS
         WHERE EXPERIMENT_ID = 'EATS_EXP_0101'
      ) A
     WHERE RN = 1
),

WIN_ORDERS AS (
    SELECT
        A.VARIANT,
        A.USER_ID
     FROM BASE_ASSIGN A
     INNER JOIN ORDERS B
       ON A.USER_ID = B.USER_ID
      AND B.IS_COMPLETED = TRUE
      AND B.ORDER_TS >= A.ASSIGNED_AT
      AND B.ORDER_TS < A.ASSIGNED_AT + INTERVAL '7' day
    GROUP BY A.VARIANT, A.USER_ID
)

SELECT
    A.VARIANT,
    COUNT(DISTINCT A.USER_ID) AS ASSIGNED_USERS,
    COUNT(DISTINCT B.USER_ID) AS CONVERTERS,
    CAST(COUNT(DISTINCT B.USER_ID) AS DOUBLE)
    / NULLIF(COUNT(DISTINCT A.USER_ID), 0) AS CONVERSION_RATE
  FROM BASE_ASSIGN A
  LEFT JOIN WIN_ORDERS B
    ON A.VARIANT = B.VARIANT
   AND A.USER_ID = B.USER_ID
 GROUP BY A.VARIANT