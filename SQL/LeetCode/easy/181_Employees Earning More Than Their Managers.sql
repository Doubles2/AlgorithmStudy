-- Write your PostgreSQL query statement below
/*
 *  관리자는 모두 0일 수 있나..일단 관리자의 관리자는 없다는 가정하에 풀기
 */
WITH BASE AS (
 SELECT
    A.ID,
    A.NAME,
    A.SALARY,
    A.MANAGERID,
    B.NAME AS MANAGER_NAME,
    B.SALARY AS MANAGER_SALARY
FROM
    EMPLOYEE    A
LEFT JOIN
    EMPLOYEE    B
ON
    A.MANAGERID = B.ID
)
SELECT
    NAME AS EMPLOYEE
FROM
    BASE
WHERE
    SALARY > MANAGER_SALARY