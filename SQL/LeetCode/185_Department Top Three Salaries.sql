-- Write your PostgreSQL query statement below
WITH BASE AS (
    /* 부서 구분을 위한 BASE */
    SELECT
        A.*,
        B.NAME AS DEPARTMENT
    FROM
        EMPLOYEE    A
    LEFT JOIN
        DEPARTMENT  B
    ON  A.DEPARTMENTID = B.ID
), 
AGG AS (
    SELECT
        DEPARTMENT,
        NAME AS EMPLOYEE,
        SALARY,
        DENSE_RANK() OVER (
            PARTITION BY DEPARTMENT
            ORDER BY SALARY DESC
        ) AS RANK_SALARY
    FROM
        BASE
)
SELECT
    DEPARTMENT,
    EMPLOYEE,
    SALARY
FROM
    AGG
WHERE
    1=1
AND
    RANK_SALARY <= 3