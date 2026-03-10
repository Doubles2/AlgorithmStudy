-- Write your PostgreSQL query statement below
SELECT
    QUERY_NAME,
    ROUND(
        SUM(RATING / NULLIF(POSITION, 0))
        / NULLIF(COUNT(*), 0) 
        , 2
    ) AS QUALITY,
    ROUND(        
        SUM(CASE WHEN RATING < 3 THEN 1 ELSE 0 END) 
        / NULLIF(COUNT(*), 0)
        * 100
        , 2
    ) AS POOR_QUERY_PERCENTAGE
  FROM QUERIES
 GROUP BY QUERY_NAME