# Write your MySQL query statement below
WITH BASE_DRN AS (
    SELECT
        PRODUCT_ID,
        YEAR,
        QUANTITY,
        PRICE,
        DENSE_RANK() OVER (
            PARTITION BY PRODUCT_ID
            ORDER BY YEAR
        ) AS DRK
      FROM SALES
)
SELECT
    PRODUCT_ID,
    YEAR AS FIRST_YEAR,
    QUANTITY,
    PRICE
  FROM BASE_DRN
 WHERE DRK = 1