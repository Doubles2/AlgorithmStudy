/*
 * 아래와 같이 푸는 유형은 처음 봤음.
 * 다만, RETURN QUERY () 안에 SQL 작성하더라도 별칭을 다 선언해야 함
 */
CREATE OR REPLACE FUNCTION NthHighestSalary(N INT) RETURNS TABLE (Salary INT) AS $$
BEGIN
  RETURN QUERY (
    -- Write your PostgreSQL query statement below.
    SELECT
        DISTINCT A.SALARY

    FROM (
        SELECT
            A1.SALARY,
            DENSE_RANK() OVER (
                ORDER BY A1.SALARY DESC
            ) AS RANK_SALARY
        FROM 
            EMPLOYEE A1
    ) A
    WHERE
        A.RANK_SALARY = N
      
  );
END;
$$ LANGUAGE plpgsql;