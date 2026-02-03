-- Write your PostgreSQL query statement below
SELECT
    A.NAME,
    B.BONUS
FROM
    EMPLOYEE A
LEFT JOIN
    BONUS B
ON
    A.EMPID = B.EMPID
WHERE
    1=1
AND
    COALESCE(B.BONUS, 0) < 1000