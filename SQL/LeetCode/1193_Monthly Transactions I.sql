SELECT
    DATE_FORMAT(TRANS_DATE, '%Y-%m') AS month,
    COUNTRY,
    COUNT(*) AS trans_count,
    SUM(CASE WHEN LOWER(TRIM(STATE)) = 'approved' THEN 1 ELSE 0 END) AS approved_count,
    SUM(AMOUNT) AS trans_total_amount,
    SUM(CASE WHEN LOWER(TRIM(STATE)) = 'approved' THEN AMOUNT ELSE 0 END) AS approved_total_amount
  FROM Transactions
 GROUP BY DATE_FORMAT(TRANS_DATE, '%Y-%m'), COUNTRY;