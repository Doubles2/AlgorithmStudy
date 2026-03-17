/* ***************************************
 * 제출: 통과
 * ***************************************/
WITH BASE_CLIENT AS (
    SELECT
        T.ID,
        T.STATUS,
        T.REQUEST_AT
      FROM TRIPS T
     INNER JOIN (
        SELECT
            USERS_ID
          FROM USERS
         WHERE BANNED = 'No'
           AND ROLE = 'client'
     ) u
        ON T.CLIENT_ID = U.USERS_ID
     where T.REQUEST_AT >= DATE '2013-10-01'
       AND T.REQUEST_AT <= DATE '2013-10-03'
),
BASE_DRIVER AS (
    SELECT
        T.ID
      FROM TRIPS T
     INNER JOIN (
        SELECT
            USERS_ID
          FROM USERS
         WHERE BANNED = 'No'
           AND ROLE = 'driver'
     ) u 
        ON T.driver_id = U.USERS_ID
     where T.REQUEST_AT >= DATE '2013-10-01'
       AND T.REQUEST_AT <= DATE '2013-10-03'
),
raw as (
    SELECT
        bc.id,
        bc.status,
        bc.REQUEST_AT
      from BASE_CLIENT bc
     inner join base_driver bd
        on bc.id = bd.id
)
SELECT
    REQUEST_AT AS DAY,
    ROUND(
        COUNT(CASE WHEN STATUS not in ('completed') THEN STATUS ELSE NULL END)
        / COUNT(*)
        , 2
    ) AS "CANCELLATION RATE"
  FROM raw
 group by 1

/* ***********************************************************************
 try1

 [왜 틀렸는가]
 1. 문제를 끝까지 정확히 읽지 않았다.
    - 핵심 조건: both client and driver must not be banned
    - client만 보면 안 되고 driver도 banned = 'No' 이어야 한다.

 2. 분모가 되는 "유효한 trip"의 기준을 먼저 정의하지 않았다.
    - 이 문제는 취소 건수를 세는 문제 이전에
      "어떤 trip을 계산 대상에 넣을 것인가"를 먼저 정해야 한다.
    - 유효한 trip = client, driver 모두 banned = 'No' 인 trip

 3. 날짜 조건과 출력 형식을 꼼꼼히 확인하지 않았다.
    - 날짜 범위를 정확히 맞춰야 한다.
    - 출력 컬럼명도 문제에서 요구한 형식대로 맞춰야 한다.

 4. coalesce가 핵심이라고 착각했다.
    - 이 문제는 null 처리보다
      "집계 대상 row를 정확히 거르는 것"이 핵심이다.
    - 즉, coalesce 문제가 아니라 문제 해석 문제였다.

 [짚고 넘어갈 포인트]
 1. 비율(rate) 문제는 분자보다 분모를 먼저 정의한다.
    - 취소율 = 취소 건수 / 전체 유효 trip 수
    - 항상 "무엇이 전체인가?"를 먼저 생각할 것

 2. 조건이 여러 개인 문제는 기준 테이블을 먼저 정한다.
    - 이 문제의 기준 테이블은 TRIPS
    - 그 다음 client용 USERS, driver용 USERS를 각각 붙여야 한다.

 3. 상태값 비교는 애매하게 쓰지 말고 명시적으로 쓴다.
    - status != 'completed'
    - 보다는
      status IN ('cancelled_by_driver', 'cancelled_by_client')
      가 더 명확하다.

 4. COUNT / COUNT 는 정수 나눗셈 가능성을 항상 의심한다.
    - DB에 따라 0으로 잘릴 수 있으므로
      1.0 * COUNT(...) / COUNT(*)
      또는 CAST(...)를 고려할 것

 5. CASE WHEN COUNT 용도면 THEN 1로 쓴다.
    - THEN status 보다 THEN 1 이 의도가 더 명확하고 깔끔하다.

 6. 같은 기준 테이블을 여러 번 읽고 있지 않은지 점검한다.
    - TRIPS를 두 번 읽는 구조도 가능은 하지만
      보통은 TRIPS 1번 + USERS 2번 join이 더 자연스럽고 효율적이다.

 [이번 문제의 핵심 한 줄]
 - 이 문제는 "취소 건수 세기" 문제가 아니라
   "유효한 trip 집합을 정확히 정의한 뒤 날짜별 취소율을 계산하는 문제"다.

 [다음에 같은 유형 나오면]
 1. 기준 테이블 확인
 2. 집계 대상 조건 정의
 3. 분모/분자 정의
 4. 날짜 범위 확인
 5. 출력 컬럼명 확인
 6. 정수 나눗셈 여부 확인

 문제를 대충 읽고 SQL부터 치지 말자.
 먼저 "누가 계산 대상인지"를 정의하고 시작하자.
 *********************************************************************** */


 WITH valid_trips AS (
    SELECT
        t.request_at,
        t.status
    FROM trips t
    INNER JOIN users c
        ON t.client_id = c.users_id
       AND c.banned = 'No'
       AND c.role = 'client'
    INNER JOIN users d
        ON t.driver_id = d.users_id
       AND d.banned = 'No'
       AND d.role = 'driver'
    WHERE t.request_at >= DATE '2013-10-01'
      AND t.request_at <= DATE '2013-10-03'
)
SELECT
    request_at AS Day,
    ROUND(
        1.0 * COUNT(
            CASE
                WHEN status IN ('cancelled_by_driver', 'cancelled_by_client') THEN 1
            END
        ) / COUNT(*),
        2
    ) AS "Cancellation Rate"
FROM valid_trips
GROUP BY request_at
ORDER BY request_at;