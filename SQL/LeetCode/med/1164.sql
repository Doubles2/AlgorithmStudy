with base_price as (
    select
        distinct product_id,
        10 as new_price
      from products
)
, recent_price as (
select
    product_id,
    new_price,
    change_date
  from (
    select
        product_id,
        new_price,
        change_date,
        row_number() over (
            partition by product_id
            order by change_date desc
        ) as rn
    from products
    where change_date <= '2019-08-16'
  ) bs
 where rn = 1
)
select
    bp.product_id,
    case when rp.new_price is null then bp.new_price
         else rp.new_price
    end as price
  from base_price bp
  left
  join recent_price rp
    on bp.product_id = rp.product_id


-- ============== GPT 추가 설명 ==============
-- 1) 전체 상품 목록을 먼저 구한다.
--    문제에서 "모든 상품"의 가격을 구해야 하므로,
--    가격 변경 이력이 없더라도 상품은 결과에 포함되어야 한다.
WITH product_list AS (
    SELECT DISTINCT product_id
    FROM Products
),

-- 2) 기준일(2019-08-16) 이전까지의 가격 이력만 남긴다.
--    그중에서 상품별 가장 최근 가격 1건을 찾기 위해
--    ROW_NUMBER()를 사용해 change_date 내림차순으로 순번을 매긴다.
recent_price AS (
    SELECT product_id, new_price
    FROM (
        SELECT
            product_id,
            new_price,
            ROW_NUMBER() OVER (
                PARTITION BY product_id
                ORDER BY change_date DESC
            ) AS rn
        FROM Products
        WHERE change_date <= '2019-08-16'
    ) t
    -- 3) rn = 1 은 상품별로 기준일 이전의 "가장 최근 가격"을 의미한다.
    WHERE rn = 1
)

-- 4) 전체 상품 목록을 기준으로 recent_price를 LEFT JOIN 한다.
--    -> 최근 가격 이력이 있는 상품은 그 가격을 사용
--    -> 최근 가격 이력이 없는 상품은 NULL 이므로 기본값 10을 사용
SELECT
    p.product_id,
    COALESCE(r.new_price, 10) AS price
FROM product_list p
LEFT JOIN recent_price r
    ON p.product_id = r.product_id;