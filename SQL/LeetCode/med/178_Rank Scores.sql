-- 같은 값이 있으면 1, 1을 주고 다음 값이 2부터 시작하게 하려면 DENSE_RANK()
-- 건너뛰어서 3부터 시작하게 하려면 RANK()
SELECT 
    SCORE,
    DENSE_RANK() OVER (
        ORDER BY SCORE DESC
    ) AS RANK
FROM
    SCORES