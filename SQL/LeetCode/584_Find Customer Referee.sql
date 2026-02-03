-- Write your PostgreSQL query statement below
SELECT
    NAME
FROM    
    CUSTOMER
WHERE
    1=1
AND
    COALESCE(REFEREE_ID, 0) != 2