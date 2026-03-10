/* ********************************************
 * 서브쿼리
 * ******************************************** */
SELECT
    BSM.HACKER_ID,
    H.NAME,
    SUM(BSM.SCORE) AS SCORE
  FROM (
    SELECT
        CHALLENGE_ID,
        HACKER_ID,
        MAX(SCORE) AS SCORE
      FROM SUBMISSIONS
     GROUP BY 1, 2
  ) BSM
  LEFT JOIN HACKERS H
    ON BSM.HACKER_ID = H.HACKER_ID
 GROUP BY 1, 2
 HAVING SUM(BSM.SCORE) > 0
 ORDER BY 3 DESC, 1

/* ******************************************** */

/* ********************************************
 * CTE
 * ******************************************** */
WITH BASE_SM AS (
    SELECT
        CHALLENGE_ID,
        HACKER_ID,
        MAX(SCORE) AS SCORE
      FROM SUBMISSIONS
     GROUP BY 1, 2
)
SELECT
    BSM.HACKER_ID,
    H.NAME,
    SUM(SCORE) AS SCORE
  FROM BASE_SM BSM
  LEFT JOIN HACKERS H
    ON BSM.HACKER_ID = H.HACKER_ID
 GROUP BY 1, 2
 HAVING SUM(SCORE) > 0
 ORDER BY 3 DESC, 1