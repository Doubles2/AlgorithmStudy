WITH BASE_TIV AS (
    SELECT
        I.*
      FROM INSURANCE I
     INNER
      JOIN (
        SELECT
            TIV_2015,
            COUNT(TIV_2015) AS CNT
        FROM INSURANCE
        GROUP BY TIV_2015
        HAVING COUNT(TIV_2015) > 1
      ) II
        ON I.TIV_2015 = II.TIV_2015
),
UNIQ_LOC AS (
    SELECT
        LAT,
        LON,
        COUNT(*) AS CNT
      FROM INSURANCE
     GROUP BY LAT, LON
     HAVING COUNT(*) = 1
),
RAW AS (
    SELECT
        BT.TIV_2015,
        BT.TIV_2016
      FROM BASE_TIV BT
     INNER
      JOIN UNIQ_LOC UL
        ON BT.LAT = UL.LAT
       AND BT.LON = UL.LON
)
SELECT
    ROUND(SUM(TIV_2016) * 1.0, 2) AS TIV_2016
  FROM RAW