/* =======================================================================
   공통 데이터 스키마 (문제 C1 ~ C3 사용)  [MySQL 8.0 기준]

   1) orders
      order_id (BIGINT)
      customer_id (BIGINT)
      ordered_at (TIMESTAMP)
      order_date (DATE)
      status_code (INT)     -- 60 = completed, 70 = canceled
      gmv (DECIMAL)

   2) deliveries
      order_id (BIGINT)
      picked_up_at (TIMESTAMP)
      delivered_at (TIMESTAMP)
      estimated_minutes (INT)

   3) ab_assignments
      experiment_id (VARCHAR)
      customer_id (BIGINT)
      variant (VARCHAR)     -- 'A' | 'B'
      assigned_at (TIMESTAMP)

   공통 가정
      - 완료 주문만 볼 때는 status_code = 60 사용
      - 기간 조건은 >= start AND < end 반개구간 사용
      - 날짜 기준 문제에서는 DATE, 시간 기준 문제에서는 TIMESTAMP 사용
      - 고객 단위 지표와 주문 단위 지표를 혼동하지 않도록 grain을 먼저 맞출 것
   ======================================================================= */


/* =======================================================================
   문제 C1) 최근 6개월 기준 고객 세그먼트 분류 (난이도: 중)

   요구
      기준일: 2026-03-01
      최근 6개월: 2025-09-01 ~ 2026-02-28

      완료 주문(status_code = 60) 기준으로
      최근 6개월 내 구매한 고객을 아래 기준으로 분류하세요.

      new:
          최근 6개월 내 첫 완료 주문이 발생했고,
          그 이전 완료 주문 이력이 없는 고객

      reactive:
          최근 6개월 내 완료 주문이 있고,
          최근 6개월 내 첫 완료 주문일과 그 직전 완료 주문일의 차이가 90일 이상인 고객

      existing:
          최근 6개월 내 완료 주문이 있고,
          new / reactive가 아닌 고객

   출력 컬럼
      customer_id,
      segment,
      first_order_in_6m,
      last_order_before_6m

   포인트
      - recent 구간 주문 전체를 바로 분류하면 고객별 중복 행이 생길 수 있음
      - 먼저 "최근 6개월 내 첫 주문"을 고객 단위로 구해야 함
      - reactive는 "최근 6개월 내 첫 주문"과 "그 직전 주문"의 차이로 판정
   ======================================================================= */
WITH completed_orders AS (
    SELECT
        customer_id,
        order_date
    FROM orders
    WHERE status_code = 60
),
first_order_6m AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_in_6m
    FROM completed_orders
    WHERE order_date >= DATE '2025-09-01'
      AND order_date <  DATE '2026-03-01'
    GROUP BY customer_id
),
customer_history AS (
    SELECT
        f.customer_id,
        f.first_order_in_6m,
        MAX(c.order_date) AS last_order_before_6m
    FROM first_order_6m f
    LEFT JOIN completed_orders c
      ON f.customer_id = c.customer_id
     AND c.order_date < f.first_order_in_6m
    GROUP BY
        f.customer_id,
        f.first_order_in_6m
)
SELECT
    customer_id,
    CASE
        WHEN last_order_before_6m IS NULL THEN 'new'
        WHEN DATEDIFF(first_order_in_6m, last_order_before_6m) >= 90 THEN 'reactive'
        ELSE 'existing'
    END AS segment,
    first_order_in_6m,
    last_order_before_6m
FROM customer_history
ORDER BY customer_id;


/* =======================================================================
   문제 C2) 배송 지연 보상 대상 고객 계산 (난이도: 중)

   요구
      2026-02-01 ~ 2026-03-01 기간의 완료 주문(status_code = 60)을 대상으로,
      실제 배달 소요 시간이 예상 배달 시간보다 15분 이상 늦은 주문을
      "보상 대상 주문"으로 정의합니다.

   정의
      actual_delivery_minutes:
          TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at)

      delayed_order:
          actual_delivery_minutes - estimated_minutes >= 15

   고객별로 아래 지표를 구하세요.

      total_completed_orders:
          해당 기간 완료 주문 수

      delayed_orders:
          보상 대상 주문 수

      delay_rate:
          delayed_orders / total_completed_orders

      compensation_flag:
          delayed_orders >= 2 이면 'Y', 아니면 'N'

   출력 컬럼
      customer_id,
      total_completed_orders,
      delayed_orders,
      delay_rate,
      compensation_flag

   포인트
      - 분모는 완료 주문 전체를 기준으로 유지
      - deliveries 정보가 없어도 완료 주문 자체는 포함될 수 있으므로 LEFT JOIN 고려
      - 고객 단위 집계 전에 주문 단위로 지연 여부를 먼저 계산
   ======================================================================= */
WITH base_orders AS (
    SELECT
        customer_id,
        order_id,
        ordered_at
    FROM orders
    WHERE ordered_at >= TIMESTAMP '2026-02-01 00:00:00'
      AND ordered_at <  TIMESTAMP '2026-03-01 00:00:00'
      AND status_code = 60
),
ord_deliv_raw AS (
    SELECT
        bo.customer_id,
        bo.order_id,
        CASE
            WHEN d.delivered_at IS NOT NULL
             AND TIMESTAMPDIFF(MINUTE, bo.ordered_at, d.delivered_at) - d.estimated_minutes >= 15
            THEN 1
            ELSE 0
        END AS comp_yn
    FROM base_orders bo
    LEFT JOIN deliveries d
      ON bo.order_id = d.order_id
)
SELECT
    customer_id,
    COUNT(*) AS total_completed_orders,
    SUM(comp_yn) AS delayed_orders,
    1.0 * SUM(comp_yn) / NULLIF(COUNT(*), 0) AS delay_rate,
    CASE
        WHEN SUM(comp_yn) >= 2 THEN 'Y'
        ELSE 'N'
    END AS compensation_flag
FROM ord_deliv_raw
GROUP BY customer_id
ORDER BY customer_id;


/* =======================================================================
   문제 C3) 실험군별 배정 후 7일 이내 재주문율 비교 (난이도: 중)

   요구
      experiment_id = 'EATS_EXP_0101' 인 A/B 테스트에 대해,
      2026-02-01 ~ 2026-03-01 기간에 배정된 고객을 대상으로
      variant별 7일 내 성과를 비교하세요.

   조건
      - 고객별 가장 이른 배정 1건만 인정
      - completed 주문만 포함 (status_code = 60)
      - 배정 후 7일 이내 주문 정의:
          ordered_at >= assigned_at
          AND ordered_at < assigned_at + INTERVAL 7 DAY

   KPI 정의
      assigned_customers:
          배정 고객 수

      customers_with_order_in_7d:
          배정 후 7일 이내 completed 주문이 1건 이상 있는 고객 수

      reorder_rate_7d:
          customers_with_order_in_7d / assigned_customers

      avg_gmv_per_order_in_7d:
          배정 후 7일 이내 completed 주문들의 평균 gmv

   출력 컬럼
      variant,
      assigned_customers,
      customers_with_order_in_7d,
      reorder_rate_7d,
      avg_gmv_per_order_in_7d

   포인트
      - base_assign에서 고객별 최초 배정 1건 dedup 필수
      - reorder_rate는 고객 단위 distinct 기준
      - avg_gmv는 주문 단위 기준
      - 고객 수와 주문 수 grain을 섞지 않도록 주의
   ======================================================================= */
WITH base_assign AS (
    SELECT
        customer_id,
        variant,
        assigned_at
    FROM (
        SELECT
            experiment_id,
            customer_id,
            variant,
            assigned_at,
            ROW_NUMBER() OVER (
                PARTITION BY experiment_id, customer_id
                ORDER BY assigned_at
            ) AS rn
        FROM ab_assignments
        WHERE experiment_id = 'EATS_EXP_0101'
          AND assigned_at >= TIMESTAMP '2026-02-01 00:00:00'
          AND assigned_at <  TIMESTAMP '2026-03-01 00:00:00'
    ) t
    WHERE rn = 1
),
assign_ord_raw AS (
    SELECT
        ba.customer_id,
        ba.variant,
        o.order_id,
        o.gmv
    FROM base_assign ba
    LEFT JOIN orders o
      ON ba.customer_id = o.customer_id
     AND o.status_code = 60
     AND o.ordered_at >= ba.assigned_at
     AND o.ordered_at <  ba.assigned_at + INTERVAL 7 DAY
)
SELECT
    variant,
    COUNT(DISTINCT customer_id) AS assigned_customers,
    COUNT(DISTINCT CASE WHEN order_id IS NOT NULL THEN customer_id END) AS customers_with_order_in_7d,
    1.0 * COUNT(DISTINCT CASE WHEN order_id IS NOT NULL THEN customer_id END)
        / NULLIF(COUNT(DISTINCT customer_id), 0) AS reorder_rate_7d,
    AVG(CASE WHEN order_id IS NOT NULL THEN gmv END) AS avg_gmv_per_order_in_7d
FROM assign_ord_raw
GROUP BY variant
ORDER BY variant;