SELECT
    DATE_FORMAT(TRANS_DATE, '%Y-%m') AS month,
    COUNTRY,
    COUNT(*) AS trans_count,
    SUM(CASE WHEN LOWER(TRIM(STATE)) = 'approved' THEN 1 ELSE 0 END) AS approved_count,
    SUM(AMOUNT) AS trans_total_amount,
    SUM(CASE WHEN LOWER(TRIM(STATE)) = 'approved' THEN AMOUNT ELSE 0 END) AS approved_total_amount
  FROM Transactions
 GROUP BY DATE_FORMAT(TRANS_DATE, '%Y-%m'), COUNTRY;

 /* ======================== 한 번 더 풀이 ============================= */

 select
    date_format(trans_date, '%Y-%m') as month,
    country,
    count(*) as trans_count,
    sum(case when state = 'approved' then 1 else 0 end) as approved_count,
    sum(amount) as trans_total_amount,
    sum(case when state = 'approved' then amount else 0 end) as approved_total_amount
  from transactions
 group by 1, 2