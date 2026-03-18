-- Write your PostgreSQL query statement below

SELECT
    DISTINCT EMAIL
FROM (
    SELECT
        EMAIL,
        ROW_NUMBER() OVER (PARTITION BY EMAIL) AS RN
    FROM
        PERSON
)
WHERE
    RN >= 2