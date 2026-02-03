/* 
 * 문제 자체에서 DELETE를 사용하라고 적혀있는 문제!
 */
WITH p AS (
    SELECT
        id,
        email,
        ROW_NUMBER() OVER (PARTITION BY email ORDER BY id) AS rn
    FROM Person
)
DELETE FROM Person
WHERE id IN (SELECT id FROM p WHERE rn > 1);
