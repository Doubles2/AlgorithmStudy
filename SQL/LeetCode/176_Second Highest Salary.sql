-- Write your PostgreSQL query statement below
SELECT
    MAX(CASE WHEN RANK = 2 THEN SALARY ELSE NULL END) AS SecondHighestSalary 
FROM (
    SELECT
        ID,
        SALARY,
        DENSE_RANK() OVER (
            ORDER BY SALARY DESC
        ) AS RANK
    FROM
        EMPLOYEE
)