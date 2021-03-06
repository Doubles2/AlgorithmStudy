-- #1
SELECT COUNT(ANIMAL_ID)
  FROM ANIMAL_INS;

-- #2
SELECT COUNT(DISTINCT NAME)
  FROM ANIMAL_INS

-- #3
SELECT ANIMAL_TYPE
     , COUNT(ANIMAL_ID)
  FROM ANIMAL_INS
 GROUP BY ANIMAL_TYPE
 ORDER BY ANIMAL_TYPE;

-- #4
SELECT NAME
     , COUNT(ANIMAL_ID)
  FROM ANIMAL_INS
 GROUP BY NAME
 HAVING COUNT(NAME) >= 2 
 ORDER BY NAME