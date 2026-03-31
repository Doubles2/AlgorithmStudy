# Write your MySQL query statement below
WITH BASE AS (
    SELECT
        NUM,
        DIFF,
        COUNT(*) AS CNT
    FROM (
        SELECT
            ID,
            NUM,
            ID - ROW_NUMBER() OVER (
                    PARTITION BY NUM
                    ORDER BY ID
                ) AS DIFF
        FROM LOGS
    ) BS
    GROUP BY 1, 2
)
SELECT
    NUM AS ConsecutiveNums 
  FROM BASE
 WHERE CNT >= 3