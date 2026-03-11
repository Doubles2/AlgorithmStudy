/* =======================================================================
   공통 데이터 스키마 (문제 F1 ~ F3 사용)  [MySQL 8.0 기준]

   1) orders
      order_id (BIGINT)
      customer_id (BIGINT)
      ordered_at (TIMESTAMP)
      status_code (INT)       -- 60 = completed, 70 = canceled
      gmv (DECIMAL(10,2))

   2) deliveries
      order_id (BIGINT)
      delivered_at (TIMESTAMP)
      estimated_minutes (INT)

   3) ab_assignments
      experiment_id (VARCHAR)
      customer_id (BIGINT)
      variant (VARCHAR)       -- 'A' | 'B'
      assigned_at (TIMESTAMP)

   공통 가정
      - 완료 주문은 status_code = 60
      - 기간 조건은 >= start AND < end 반개구간 사용
      - "배정 후 7일" 조건:
          ordered_at >= assigned_at
          AND ordered_at < assigned_at + INTERVAL 7 DAY
      - 고객 단위 지표와 주문 단위 지표를 구분할 것
   ======================================================================= */


/* =======================================================================
   문제 F1) 최근 6개월 기준 고객 세그먼트 분류 + 고객 수 집계 (난이도: 중)

   요구
      기준일: 2026-03-01
      최근 6개월: 2025-09-01 ~ 2026-02-28

      완료 주문(status_code = 60) 기준으로
      최근 6개월 내 구매한 고객을 아래와 같이 분류하세요.

      new:
          최근 6개월 내 첫 완료 주문이 발생했고,
          그 이전 완료 주문 이력이 없는 고객

      reactive:
          최근 6개월 내 완료 주문이 있고,
          최근 6개월 내 첫 완료 주문일과 그 직전 완료 주문일 차이가 90일 이상인 고객

      existing:
          최근 6개월 내 완료 주문이 있고,
          new / reactive 가 아닌 고객

   출력 컬럼
      segment,
      customer_cnt

   포인트
      - 고객별 최근 6개월 내 "첫 주문" 기준으로 판정
      - recent 구간 전체 주문으로 바로 분류하면 중복될 수 있음
      - reactive는 직전 완료 주문과의 간격으로 계산
   ======================================================================= */
WITH BASE_ORDERS_COMP AS (
	SELECT
		CUSTOMER_ID,
		ORDERED_AT
	  FROM ORDERS
	 WHERE STATUS_CODE = 60
),
TB_ORDERS_TARGET_6M AS (
	SELECT
		CUSTOMER_ID,
		MIN(ORDERED_AT) AS FIRST_ORDER_DATE_IN_6M
	  FROM BASE_ORDERS_COMP
	 WHERE ORDERED_AT >= DATE '2025-09-01'
	   AND ORDERED_AT <  DATE '2026-03-01'
     GROUP BY 1
),
TB_ORDERS_ORI_6M_RAW AS (
	SELECT
		TOT.CUSTOMER_ID,
		TOT.FIRST_ORDER_DATE_IN_6M,
		MAX(BO.ORDERED_AT) AS LAST_ORDER_DATE_BF_6M
	  FROM TB_ORDERS_TARGET_6M TOT
	  LEFT JOIN BASE_ORDERS_COMP BO
	    ON TOT.CUSTOMER_ID = BO.CUSTOMER_ID
	   AND BO.ORDERED_AT < TOT.FIRST_ORDER_DATE_IN_6M
	 GROUP BY 1, 2
),
TB_CUSTOMER_SEG_AGG AS (
SELECT
	CUSTOMER_ID,
	CASE WHEN LAST_ORDER_DATE_BF_6M IS NULL THEN 'NEW'
		 WHEN LAST_ORDER_DATE_BF_6M IS NOT NULL
		  AND DATEDIFF(FIRST_ORDER_DATE_IN_6M, LAST_ORDER_DATE_BF_6M) >= 90 THEN 'REACTIVE'
		 ELSE 'EXISTING'
	END AS SEGMENT
  FROM TB_ORDERS_ORI_6M_RAW
)
SELECT
	SEGMENT,
	COUNT(CUSTOMER_ID) AS CUSTOMER_CNT
  FROM TB_CUSTOMER_SEG_AGG
 GROUP BY 1
 ORDER BY 1

/* =======================================================================
   문제 F2) 배송 지연 보상 대상 고객 산출 (난이도: 중)

   요구
      2026-02-01 ~ 2026-03-01 기간의 완료 주문(status_code = 60)을 기준으로
      실제 배달 소요 시간이 예상 배달 시간보다 20분 이상 늦은 주문을
      "보상 대상 주문"으로 정의합니다.

   정의
      actual_delivery_minutes:
          TIMESTAMPDIFF(MINUTE, ordered_at, delivered_at)

      delayed_order:
          actual_delivery_minutes - estimated_minutes >= 20

   고객별 아래 지표를 계산하세요.

      total_completed_orders:
          해당 기간 완료 주문 수

      delayed_orders:
          보상 대상 주문 수

      delay_rate:
          delayed_orders / total_completed_orders

   출력 컬럼
      customer_id,
      total_completed_orders,
      delayed_orders,
      delay_rate

   추가 조건
      - 배송 정보가 없는 완료 주문도 전체 완료 주문 수에는 포함
      - 따라서 JOIN 전략을 스스로 선택하고 설명 가능해야 함

   포인트
      - 주문 단위에서 먼저 지연 여부 계산
      - LEFT JOIN vs INNER JOIN 선택 이유 설명 준비
      - 분모는 완료 주문 전체 기준
   ======================================================================= */
WITH BASE_ORDER AS (
    SELECT
        CUSTOMER_ID,
        ORDER_ID,
        ORDERED_AT
    FROM ORDERS
    WHERE ORDERED_AT >= TIMESTAMP '2026-02-01 00:00:00'
      AND ORDERED_AT <  TIMESTAMP '2026-03-01 00:00:00'
      AND STATUS_CODE = 60
),
TB_DELAY_ORDER AS (
    SELECT
        BO.CUSTOMER_ID,
        BO.ORDER_ID,
        BO.ORDERED_AT,
        D.DELIVERED_AT,
        CASE 
            WHEN D.DELIVERED_AT IS NOT NULL
             AND TIMESTAMPDIFF(MINUTE, BO.ORDERED_AT, D.DELIVERED_AT) - D.ESTIMATED_MINUTES >= 20
            THEN 1 
            ELSE 0
        END AS DELAY_ORDER_YN
    FROM BASE_ORDER BO
    LEFT JOIN DELIVERIES D
      ON BO.ORDER_ID = D.ORDER_ID
)
SELECT
    CUSTOMER_ID,
    COUNT(*) AS TOTAL_COMPLETED_ORDERS,
    SUM(DELAY_ORDER_YN) AS DELAYED_ORDERS,
    SUM(DELAY_ORDER_YN) * 1.0 / NULLIF(COUNT(*), 0) AS DELAY_RATE
FROM TB_DELAY_ORDER
GROUP BY CUSTOMER_ID
ORDER BY CUSTOMER_ID;

/* =======================================================================
   문제 F3) A/B 테스트 7일 전환율 + 평균 GMV 비교 (난이도: 중)

   요구
      experiment_id = 'EATS_EXP_0101' 인 테스트에 대해,
      2026-02-01 ~ 2026-03-01 기간에 배정된 고객의 variant별 성과를 구하세요.

   조건
      - 고객별 가장 이른 배정 1건만 인정
      - completed 주문(status_code = 60)만 포함
      - 배정 후 7일 이내 주문만 인정

   KPI 정의
      assigned_customers:
          배정 고객 수

      converters_7d:
          배정 후 7일 이내 완료 주문이 1건 이상 있는 고객 수

      conversion_rate_7d:
          converters_7d / assigned_customers

      avg_gmv_per_completed_order_7d:
          배정 후 7일 이내 완료 주문의 평균 gmv

   출력 컬럼
      variant,
      assigned_customers,
      converters_7d,
      conversion_rate_7d,
      avg_gmv_per_completed_order_7d

   포인트
      - base_assign에서 고객별 최초 배정 dedup
      - conversion은 고객 단위 distinct
      - avg_gmv는 주문 단위
      - 고객 수와 주문 수 grain 섞이지 않도록 주의
   ======================================================================= */
   WITH BASE_ASSIGN AS (
    SELECT
        CUSTOMER_ID,
        VARIANT,
        ASSIGNED_AT
    FROM (
        SELECT
            EXPERIMENT_ID,
            CUSTOMER_ID,
            VARIANT,
            ASSIGNED_AT,
            ROW_NUMBER() OVER (
                PARTITION BY EXPERIMENT_ID, CUSTOMER_ID
                ORDER BY ASSIGNED_AT
            ) AS RN
        FROM AB_ASSIGNMENTS
        WHERE EXPERIMENT_ID = 'EATS_EXP_0101'
          AND ASSIGNED_AT >= TIMESTAMP '2026-02-01 00:00:00'
          AND ASSIGNED_AT <  TIMESTAMP '2026-03-01 00:00:00'
    ) T
    WHERE RN = 1
),
WIN_ORDER AS (
    SELECT
        BA.CUSTOMER_ID,
        BA.VARIANT,
        O.ORDER_ID,
        O.GMV
    FROM BASE_ASSIGN BA
    LEFT JOIN ORDERS O
      ON BA.CUSTOMER_ID = O.CUSTOMER_ID
     AND O.STATUS_CODE = 60
     AND O.ORDERED_AT >= BA.ASSIGNED_AT
     AND O.ORDERED_AT <  BA.ASSIGNED_AT + INTERVAL 7 DAY
)
SELECT
    VARIANT,
    COUNT(DISTINCT CUSTOMER_ID) AS ASSIGNED_CUSTOMERS,
    COUNT(DISTINCT CASE WHEN ORDER_ID IS NOT NULL THEN CUSTOMER_ID END) AS CONVERTERS_7D,
    COUNT(DISTINCT CASE WHEN ORDER_ID IS NOT NULL THEN CUSTOMER_ID END) * 1.0
        / NULLIF(COUNT(DISTINCT CUSTOMER_ID), 0) AS CONVERSION_RATE_7D,
    AVG(CASE WHEN ORDER_ID IS NOT NULL THEN GMV END) AS AVG_GMV_PER_COMPLETED_ORDER_7D
FROM WIN_ORDER
GROUP BY VARIANT
ORDER BY VARIANT;