# Write your MySQL query statement below
WITH BASE AS (
    SELECT
        S1.STUDENT_ID,
        S1.STUDENT_NAME,
        S2.SUBJECT_NAME
      FROM STUDENTS S1
     CROSS
      JOIN SUBJECTS S2
        ON 1=1
),
RAW AS (
    SELECT
        B.*,
        E.STUDENT_ID AS CHECK_STUDENT_ID
      FROM BASE B
      LEFT
      JOIN EXAMINATIONS E
        ON B.STUDENT_ID = E.STUDENT_ID
       AND B.SUBJECT_NAME = E.SUBJECT_NAME
)
SELECT
    STUDENT_ID,
    STUDENT_NAME,
    SUBJECT_NAME,
    COALESCE(COUNT(CHECK_STUDENT_ID), 0) AS attended_exams 
  FROM RAW
 GROUP BY 1, 2, 3
 ORDER BY STUDENT_ID, SUBJECT_NAME

-- LeetCode 1280
-- 목적:
-- 모든 학생(student) × 모든 과목(subject) 조합을 먼저 만든 뒤,
-- 실제 시험을 본 기록(examinations)을 붙여서 응시 횟수를 구한다.

-- 왜 CROSS JOIN을 썼는가?
-- student 테이블과 subject 테이블을 INNER JOIN으로 바로 연결할 수 있는 공통 키가 없음.
-- 두 테이블의 "모든 가능한 조합"을 만들어야 하므로 CROSS JOIN 사용.

-- 왜 INNER JOIN이 아니라 LEFT JOIN을 썼는가?
-- 문제에서 "시험을 한 번도 보지 않은 경우(count = 0)"도 결과에 포함해야 함.
-- INNER JOIN을 쓰면 examinations에 없는 조합은 아예 사라짐.
-- 따라서
-- 1) student × subject 전체 조합을 만든 뒤
-- 2) examinations를 LEFT JOIN 해서
-- 3) 없는 경우도 남기고 COUNT(examinations.subject_name)으로 0 처리

-- 핵심 흐름
-- 1. students CROSS JOIN subjects
--    -> 모든 학생-과목 조합 생성
-- 2. examinations LEFT JOIN
--    -> 실제 응시 기록 연결
-- 3. COUNT(examinations.subject_name)
--    -> 응시한 횟수 계산
--    -> 응시 기록이 없으면 NULL 이므로 COUNT 결과는 0
-- 4. student_id, student_name, subject_name 기준 GROUP BY
-- 5. student_id, subject_name 기준 ORDER BY