/* 
 * 다시 풀었을 때
 */
# Write your MySQL query statement below
WITH BASE_ACTIVITY AS (
    SELECT
        PLAYER_ID,
        EVENT_DATE,
        EVENT_DATE_2ND,
        DATEDIFF(EVENT_DATE_2ND, EVENT_DATE) AS DIFF_DD
      FROM (
        SELECT
            PLAYER_ID,
            EVENT_DATE,
            LEAD(EVENT_DATE, 1) OVER (
                PARTITION BY PLAYER_ID
                ORDER BY EVENT_DATE
            ) AS EVENT_DATE_2ND,
            ROW_NUMBER() OVER (
                PARTITION BY PLAYER_ID
                ORDER BY EVENT_DATE
            ) AS RN
          FROM ACTIVITY
      ) A
     WHERE A.RN = 1
)
SELECT
    ROUND(
        SUM(CASE WHEN DIFF_DD = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS fraction
FROM BASE_ACTIVITY

/* ======================================================================================= */

/*
 * 최초 로그인 후 이력이기에 ROW_NUMBER()도 같이 봐야해
 */
WITH BASE AS (
    SELECT
        PLAYER_ID,
        EVENT_DATE,
        LAG(EVENT_DATE, 1) OVER (PARTITION BY PLAYER_ID ORDER BY EVENT_DATE) AS EVENT_DATE_LAG1,
        ROW_NUMBER() OVER (PARTITION BY PLAYER_ID ORDER BY EVENT_DATE) AS ROWNUM_LOGIN
    FROM
        ACTIVITY
),
STEP1_LOGIN_AGAIN_PLAYER AS (
    SELECT
        '1' AS KEY,
        COUNT(DISTINCT PLAYER_ID) AS CNT_ID_AGAIN
    FROM
        BASE
    WHERE
        EVENT_DATE = EVENT_DATE_LAG1 + INTERVAL '1 DAYS'
    AND
        ROWNUM_LOGIN = 2
),
STEP2_TOTAL_PLAYER AS (
    SELECT
        '1' AS KEY,
        COUNT(DISTINCT PLAYER_ID) AS CNT_ID_TOTAL
    FROM
        BASE
)
SELECT
    CASE WHEN B.CNT_ID_TOTAL IS NULL OR B.CNT_ID_TOTAL = 0 THEN 0
         ELSE COALESCE( ROUND((A.CNT_ID_AGAIN::NUMERIC / B.CNT_ID_TOTAL ), 2), 0) 
    END AS FRACTION
FROM    
    STEP1_LOGIN_AGAIN_PLAYER     A
LEFT JOIN
    STEP2_TOTAL_PLAYER  B
ON  
    A.KEY = B.KEY