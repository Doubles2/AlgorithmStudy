# Write your MySQL query statement below
WITH BASE AS (
    SELECT
        CUSTOMER_ID,
        COUNT(DISTINCT PRODUCT_KEY) AS CNT
      FROM (
        SELECT
            P.PRODUCT_KEY,
            C.CUSTOMER_ID
        FROM PRODUCT P
        LEFT
        JOIN CUSTOMER C
            ON P.PRODUCT_KEY = C.PRODUCT_KEY
      ) BS
     GROUP BY CUSTOMER_ID
),
MS_PRODUCT AS (
    SELECT COUNT(DISTINCT PRODUCT_KEY) AS TOTAL_CNT 
      FROM PRODUCT
)
SELECT
    B.CUSTOMER_ID
  FROM BASE B
  JOIN MS_PRODUCT MP
    ON B.CNT = MP.TOTAL_CNT


-- === GPT 강의 ===
-- 핵심 아이디어:
-- "모든 상품을 구매한 고객"은
-- "고객이 구매한 서로 다른 상품 수" = "전체 상품 수" 인 고객이다.

-- 풀이 패턴:
-- 1) Product 테이블에서 전체 상품 개수를 구한다.
-- 2) Customer 테이블에서 고객별 구매한 distinct 상품 개수를 구한다.
-- 3) 두 개수가 같은 고객만 남긴다.

-- 이 유형을 보면 바로 떠올릴 것:
-- "모든 ~를 만족하는 대상 찾기" 
-- -> 전체 개수와 그룹별 distinct 개수를 비교한다.

SELECT
    customer_id
FROM Customer
GROUP BY customer_id
HAVING COUNT(DISTINCT product_key) = (
    SELECT COUNT(*) 
    FROM Product
);