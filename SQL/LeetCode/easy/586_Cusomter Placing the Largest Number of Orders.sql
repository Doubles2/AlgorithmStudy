-- Write your PostgreSQL query statement below

SELECT
    CUSTOMER_NUMBER
FROM (
    SELECT
        customer_number,
        COUNT(customer_number) AS CNT
    FROM
        ORDERS
    GROUP BY 
        1
    ORDER BY
        2 DESC
)
LIMIT 1