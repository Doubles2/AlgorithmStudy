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
    문제 1 (SQL) — A/B 테스트 KPI + 가드레일 판정 (10분)
   =======================================================================

    목표: 실험 성공 여부를 “Conversion uplift + 가드레일(배달시간)”로 판단.
    조건
        실험: experiment_id='EATS_EXP_101'
        기간: assigned_at 기준 2026-02-01 ~ 2026-02-28
        Conversion 정의: 배정 후 7일 이내(0~6일) completed 주문 1건 이상인 유저 비율
        가드레일: 배정 후 7일 이내 completed 주문의 actual_mins 평균

    성공 기준
        treatment의 conversion rate가 control 대비 +0.5%p 이상
        treatment의 avg_actual_mins가 control 대비 +1분 초과 악화 금지 (즉, delta ≤ +1)

    출력 컬럼
        variant
        assigned_users
        converters
        conversion_rate
        avg_actual_mins
        uplift_pp (treat - control, percentage point)
        guardrail_delta_mins (treat - control)
        decision ('PASS'|'FAIL')
    ======================================================================= */

/* =======================================================================
    문제 2 (SQL) — 코호트 D7 리텐션 (10분)
   =======================================================================

    목표: “신규 유저 코호트”의 D7 리텐션을 도시별로 계산.

    정의
        코호트: signup_ts의 주 시작일(월요일 00:00) 기준
        D7 리텐션: 가입 후 7~13일(포함) 사이에 completed 주문 1건 이상인 유저 비율

    출력 컬럼
        cohort_week (DATE, 주 시작일)
        city
        cohort_size
        retained_users_d7
        d7_retention_rate

    힌트(Trino): date_trunc('week', ts)는 주 시작을 일요일로 잡는 환경이 있어, 월요일 기준으로 보정하는 로직을 직접 구성하는 편이 안전합니다(예: date_add('day', 1 - day_of_week(date), date) 패턴).
 
    ======================================================================= */

 /* =======================================================================
     문제 3 (SQL) — 운영 의사결정: 지역/시간대별 필요 라이더 수 산출 (10분)
    =======================================================================

    목표: pickup_zone × hour 단위로 “필요 라이더 수”를 계산.

    정의
        시간대: date_trunc('hour', order_ts)를 hour_ts로 둠
        Demand(주문수): 해당 시간대 completed 주문 수
        Rainy hour 판정: 그 시간대 주문 중 is_rainy=true 비율이 30% 초과면 rainy hour
        라이더 처리용량:
        기본 용량: 라이더 1명당 시간당 2.5건
        rainy hour면 용량 20% 감소 → 2.5 * 0.8

    필요 라이더 수
        required_riders = ceil(demand / capacity)

    출력 컬럼
        pickup_zone
        hour_ts
        demand_orders
        rainy_ratio
        capacity_per_rider
        required_riders
    =======================================================================  */
