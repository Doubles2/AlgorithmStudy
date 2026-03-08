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

    공통 가정(명시)
        실험 ID: 'EATS_EXP_0101'
        분석 기간이 주어지면: >= start AND < end (반개구간) 패턴을 사용
        “배정 후 7일”은: order_ts >= assigned_at AND order_ts < assigned_at + interval '7' day
        유저당 1회 배정만 인정(가장 이른 assigned_at)
   ======================================================================= */

/* =======================================================================
   문제 1) A/B KPI 패널 (Conversion + GMV + Guardrail) (난이도: 중)
        요구: variant별로 아래 KPI를 한 번에 산출하세요.
        대상 배정자: assigned_at이 2026-02-01~2026-03-01(2월)인 유저
   =======================================================================

    KPI 정의
        assigned_users: 배정 유저 수(유저당 1회 배정)
        converters_7d: 배정 후 7일 이내 completed 주문 1건 이상 유저 수
        conversion_rate_7d: converters_7d / assigned_users
        gmv_sum_7d: 배정 후 7일 이내 completed 주문의 gmv 합(주문 합)
        gmv_per_assigned_user_7d: gmv_sum_7d / assigned_users
        avg_actual_mins_7d: 배정 후 7일 이내 completed 주문들의 actual_mins 평균(주문 기준)

    출력 컬럼
       variant, assigned_users, converters_7d, conversion_rate_7d, gmv_sum_7d, gmv_per_assigned_user_7d, avg_actual_mins_7d

    포인트:
        분모 유지(LEFT JOIN)
        deliveries는 order_id로 조인
        gmv는 주문 단위 합, conversion은 유저 단위 distinct

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
           AND ASSIGNED_AT >= TIMESTAMP '2026-02-01 00:00:00'
           AND ASSIGNED_AT <  TIMESTAMP '2026-03-01 00:00:00'
      ) A
     WHERE RN = 1
),
-- 배정 후 7일 이내 completed 주문
WIN_ORDERS AS (
    SELECT
        A.VARIANT,
        A.USER_ID,
        B.ORDER_ID,
        B.GMV
      FROM BASE_ASSIGN A
     INNER JOIN ORDERS B
        ON A.USER_ID = B.USER_ID
       AND B.IS_COMPLETED = TRUE
       AND B.ORDER_TS >= A.ASSIGNED_AT
       AND B.ORDER_TS < A.ASSIGNED_AT + INTERVAL '7' day
)
SELECT
    A.VARIANT,    
    COUNT(DISTINCT A.USER_ID) AS ASSIGNED_USER,
    COUNT(DISTINCT B.USER_ID) AS CONVERTERS_7D,
    CAST(COUNT(DISTINCT B.USER_ID) AS DOUBLE)
    / NULLIF(COUNT(DISTINCT A.USER_ID), 0) AS CONVERSION_RATE_7D,
    COALESCE(SUM(B.GMV), 0) AS GMV_SUM_7D,
    CAST(COALESCE(SUM(B.GMV), 0) AS DOUBLE)
    / NULLIF(COUNT(DISTINCT A.USER_ID), 0) AS gmv_per_assigned_user_7d,
    AVG(C.ACTUAL_MINS) AS AVG_ACTUAL_MINS_7D
  FROM BASE_ASSIGN A
  LEFT JOIN WIN_ORDERS B
    ON A.VARIANT = B.VARIANT
   AND A.USER_ID = B.USER_ID
  LEFT JOIN DELIVERIES C
    ON B.ORDER_ID = C.ORDER_ID
 GROUP BY A.VARIANT
 ORDER BY A.VARIANT

/* =======================================================================
   문제 2) A/B “첫 주문까지 걸린 시간” 비교 (난이도: 중)
        요구: 실험 배정 이후 첫 completed 주문까지 걸린 시간(분)의 중앙값(p50)과 평균을
              variant별로 산출하세요.
        대상 배정자: assigned_at이 2026-02-01~2026-03-01(2월)인 유저 (유저당 1회 배정)

   =======================================================================

    정의
        first_completed_order_ts:
            배정 후 7일 이내 completed 주문 중 가장 빠른 주문 시간

        time_to_first_order_min:
            first_completed_order_ts - assigned_at 의 분 단위 차이

        관측 대상(n_observed_users):
            배정 후 7일 내 completed 주문이 1건 이상 존재하는 유저만 포함
            (주문이 없는 유저는 제외)

        p50:
            중앙값은 approx_percentile(time_to_first_order_min, 0.5) 사용 가능

    출력 컬럼
        variant,
        n_observed_users,
        avg_time_to_first_order_min,
        p50_time_to_first_order_min

    포인트:
        base_assign: 유저당 1회 배정 dedup 필수
        first order: 유저별 MIN(order_ts)로 추출
        시간차: date_diff('minute', assigned_at, first_completed_order_ts)
        중앙값: approx_percentile

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
           AND ASSIGNED_AT >= TIMESTAMP '2026-02-01 00:00:00'
           AND ASSIGNED_AT <  TIMESTAMP '2026-03-01 00:00:00'
      ) A
     WHERE RN = 1
),
WIN_ORDERS_MIN_ORDER AS (
    SELECT
        A.USER_ID,
        A.VARIANT,
        B.ORDER_ID,
        B.ORDER_TS
      FROM BASE_ASSIGN A
     INNER JOIN ORDERS B
        ON A.USER_ID = B.USER_ID
       AND B.IS_COMPLETED = TRUE
       AND B.ORDER_TS >= A.ASSIGNED_AT
       AND B.ORDER_TS < INTERVAL '7' DAY
)

/* =======================================================================
   문제 3) D7 리텐션 by signup_date × city (난이도: 중)
        요구: 신규 유저 코호트의 D7 리텐션을 가입일/도시별로 계산하세요.
        대상 코호트: signup_ts가 2026-02-01~2026-03-01(2월)인 유저

   =======================================================================

    정의
        signup_date:
            date(signup_ts)

        D7 리텐션:
            가입 후 7~13일(포함) 사이 completed 주문 1건 이상 유저 비율
            - order_ts >= signup_ts + interval '7' day
            - order_ts <  signup_ts + interval '14' day

    출력 컬럼
        signup_date,
        city,
        cohort_size,
        retained_users_d7,
        d7_retention_rate

    포인트:
        분모 유지: users 코호트가 LEFT JOIN의 기준
        분자: 유저 단위(중복 주문 방지 위해 DISTINCT user_id)
        기간 조건: 반개구간(start inclusive, end exclusive) 권장

    ======================================================================= */



/* =======================================================================
   문제 4) 운영 의사결정: zone × hour “필요 라이더 수” + SLA 추정 (난이도: 중)
        요구: pickup_zone × hour_ts별 운영지표와 필요 라이더 수를 계산하세요.
        대상 주문: 2026-02-15 하루(00:00~24:00) 동안의 completed 주문

   =======================================================================

    정의
        hour_ts:
            date_trunc('hour', order_ts)

        demand_orders:
            해당 hour_ts의 completed 주문 수

        rainy_ratio:
            해당 hour_ts 주문 중 is_rainy = true 비율
            (deliveries.is_rainy 기준)

        capacity_per_rider:
            기본 2.5 건/시간
            rainy_ratio > 0.30 이면 20% 감소 → 2.0 건/시간 (2.5 * 0.8)

        required_riders:
            ceil(demand_orders / capacity_per_rider)

        sla_30m_rate:
            해당 hour_ts 주문 중 actual_mins <= 30 비율

    출력 컬럼
        pickup_zone,
        hour_ts,
        demand_orders,
        rainy_ratio,
        capacity_per_rider,
        required_riders,
        sla_30m_rate

    포인트:
        deliveries는 order_id로 조인(필수)
        분모는 주문 단위(같은 hour_ts의 completed 주문)
        조건 날짜 필터는 반개구간 권장:
            order_ts >= TIMESTAMP '2026-02-15 00:00:00'
            order_ts <  TIMESTAMP '2026-02-16 00:00:00'

    ======================================================================= */



/* =======================================================================
   문제 5) ETL/데이터모델링 감각: “유저-일자 Fact” 만들기 (난이도: 중상)
        요구: 아래 스펙의 user_day_fact를 생성하는 SELECT를 작성하세요. (DDL 불필요)
        분석 기간: 2026-02-01~2026-03-01 (order_ts 기준)

   =======================================================================

    스펙(Grain)
        user_id × dt(date) 단위로 하루 1행

    컬럼 정의
        dt:
            date(order_ts)

        user_id

        city:
            users에서 조인

        orders_cnt:
            해당일 전체 주문 수(완료 여부 무관)

        completed_orders_cnt:
            해당일 completed 주문 수

        gmv_sum:
            해당일 completed 주문 gmv 합

        avg_actual_mins:
            해당일 completed 주문의 actual_mins 평균(주문 기준)

        is_active:
            orders_cnt > 0 이면 1 else 0

        is_converted:
            completed_orders_cnt > 0 이면 1 else 0

    출력 컬럼
        dt,
        user_id,
        city,
        orders_cnt,
        completed_orders_cnt,
        gmv_sum,
        avg_actual_mins,
        is_active,
        is_converted

    포인트:
        grain 유지: dt, user_id로 GROUP BY
        deliveries는 order_id로 조인(가능하면 LEFT JOIN; completed만 avg에 반영)
        완료/비완료 분리 집계는 CASE WHEN으로 처리
        기간 필터는 반개구간 권장:
            order_ts >= TIMESTAMP '2026-02-01 00:00:00'
            order_ts <  TIMESTAMP '2026-03-01 00:00:00'

    ======================================================================= */