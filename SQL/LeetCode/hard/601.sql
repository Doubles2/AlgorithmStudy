WITH filtered AS (
    SELECT
        id,
        visit_date,
        people,
        id - ROW_NUMBER() OVER (ORDER BY id) AS grp
    FROM Stadium
    WHERE people >= 100
),
valid_groups AS (
    SELECT
        grp
    FROM filtered
    GROUP BY grp
    HAVING COUNT(*) >= 3
)
SELECT
    f.id,
    f.visit_date,
    f.people
FROM filtered f
INNER JOIN valid_groups vg
    ON f.grp = vg.grp
ORDER BY f.visit_date;


/* ***********************************************************************
 45분 동안 연속적인 수를 어떻게 잡아야하는지 고민하다가 gpt에 물어봄

 601. Human Traffic of Stadium

 [문제 핵심]
 - people >= 100 인 row들 중
   id가 3개 이상 연속인 구간의 row를 모두 출력하는 문제

 [핵심 아이디어]
 - 조건을 만족하는 row만 먼저 남긴다
 - ROW_NUMBER()를 붙인다
 - id - ROW_NUMBER() 값을 그룹 키로 사용한다
 - 연속된 구간은 같은 grp 값을 가진다

 [왜 어려웠는가]
 1. 집계 문제가 아니라 연속 구간 판별 문제다
 2. 3개만 찾는 것이 아니라 3개 이상 연속된 구간 전체를 출력해야 한다
 3. 전체 테이블 기준이 아니라 people >= 100 조건을 만족한 row 기준으로 연속성을 봐야 한다

 [반드시 기억할 것]
 1. 연속 구간 문제 -> row_number 패턴 먼저 떠올리기
 2. 필터링 후 row_number를 매겨야 한다
 3. id - row_number() 는 연속 구간을 묶는 대표 트릭이다

 [한 줄 요약]
 - 이 문제는 "100명 이상인 행을 찾는 문제"가 아니라
   "100명 이상인 행들 사이에서 연속 구간을 그룹화하는 문제"다
*********************************************************************** */