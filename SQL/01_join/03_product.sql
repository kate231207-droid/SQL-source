-- TABLE : product_dim
-- COLS  : product_id    (INT)
--         product_name  (VARCHAR)
--         category_lv1  (VARCHAR)   -- 대분류
--         category_lv2  (VARCHAR)   -- 중분류
--         brand         (VARCHAR)

-- TABLE : sales_txn
-- COLS  : txn_date, store_id, channel, customer_id, product_id, qty, net_amount

-- PURPOSE : 상품/카테고리/브랜드 기준 매출 집계 템플릿
-- INPUT   : sales_txn, product_dim
-- OUTPUT  : 기간별 카테고리·브랜드 매출, 수량, 객단가
-- NOTE    : 기간, 채널, 카테고리 필터만 수정해서 사용

WITH params AS (
    SELECT
          DATE '2025-01-01' AS start_date
        , DATE '2025-01-31' AS end_date
),

base_txn AS (
    SELECT
          t.txn_date
        , t.product_id
        , p.product_name
        , p.category_lv1
        , p.category_lv2
        , p.brand
        , t.channel
        , t.qty
        , t.net_amount
    FROM sales_txn t
    JOIN product_dim p
      ON t.product_id = p.product_id
    CROSS JOIN params prm
    WHERE t.txn_date BETWEEN prm.start_date AND prm.end_date
      -- 특정 채널만 보고 싶을 때 예시
      -- AND t.channel = 'ONLINE'
      -- 특정 카테고리만
      -- AND p.category_lv1 = 'BEAUTY'
),

agg_product AS (
    SELECT
          category_lv1
        , category_lv2
        , brand
        , channel
        , SUM(net_amount) AS sales_amt
        , SUM(qty)        AS sales_qty
        , CASE 
            WHEN SUM(qty) = 0 THEN 0
            ELSE SUM(net_amount) / SUM(qty)
          END             AS avg_price
    FROM base_txn
    GROUP BY
          category_lv1
        , category_lv2
        , brand
        , channel
)

SELECT *
FROM agg_product
ORDER BY
      category_lv1
    , category_lv2
    , brand
    , channel;