-- TABLE : sales_txn
-- COLS  : txn_date      (DATE)      -- 거래일
--         store_id      (INT)       -- 점포 ID
--         channel       (VARCHAR)   -- 채널(ONLINE/OFFLINE 등)
--         customer_id   (INT)       -- 고객 ID (없으면 NULL)
--         product_id    (INT)       -- 상품 ID
--         qty           (INT)       -- 수량
--         gross_amount  (DECIMAL)   -- 매출액(할인 전)
--         net_amount    (DECIMAL)   -- 매출액(할인 후)

-- TABLE : store_dim
-- COLS  : store_id      (INT)
--         store_name    (VARCHAR)
--         region        (VARCHAR)   -- 권역(동부/서부/온라인본부 등)
--         store_type    (VARCHAR)   -- 점포 유형(직영/가맹/온라인)

-- TABLE : product_dim
-- COLS  : product_id    (INT)
--         category      (VARCHAR)
--         brand         (VARCHAR)

-- PURPOSE : 일자/점포/채널/카테고리 기준 매출 집계 템플릿
-- INPUT   : sales_txn, store_dim, product_dim
-- OUTPUT  : txn_date, store_id, store_name, channel, category,
--           sales_amt, sales_qty, avg_price, cust_cnt
-- NOTE    : WHERE 절의 기간/채널/지역 조건만 상황에 맞게 수정해서 사용

WITH base_txn AS (
    SELECT
          t.txn_date
        , t.store_id
        , s.store_name
        , s.region
        , s.store_type
        , t.channel
        , p.category
        , p.brand
        , t.customer_id
        , t.qty
        , t.net_amount
    FROM sales_txn t
    LEFT JOIN store_dim   s ON t.store_id   = s.store_id
    LEFT JOIN product_dim p ON t.product_id = p.product_id
    WHERE 1=1
      -- 기간 필터: 필요에 따라 수정
      AND t.txn_date BETWEEN DATE '2025-01-01' AND DATE '2025-01-31'
      -- 채널 필터 예시: 특정 채널만 보고 싶으면 주석 해제
      -- AND t.channel = 'ONLINE'
      -- 지역/점포 타입 필터 예시
      -- AND s.region = '서울권'
      -- AND s.store_type = '직영'
),
agg_sales AS (
    SELECT
          txn_date
        , store_id
        , store_name
        , region
        , store_type
        , channel
        , category
        -- 집계 지표
        , SUM(net_amount)            AS sales_amt
        , SUM(qty)                   AS sales_qty
        , CASE 
            WHEN SUM(qty) = 0 THEN 0
            ELSE SUM(net_amount) / SUM(qty)
          END                        AS avg_price
        , COUNT(DISTINCT customer_id) AS cust_cnt
    FROM base_txn
    GROUP BY
          txn_date
        , store_id
        , store_name
        , region
        , store_type
        , channel
        , category
)
SELECT *
FROM agg_sales
ORDER BY
      txn_date
    , store_id
    , channel
    , category;

    