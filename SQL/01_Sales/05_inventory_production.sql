-- TABLE : inventory_daily
-- COLS  : snap_date     (DATE)      -- 재고 기준일(일별 스냅샷)
--         store_id      (INT)
--         product_id    (INT)
--         stock_qty     (INT)       -- 재고 수량

-- TABLE : production_daily
-- COLS  : prod_date     (DATE)
--         product_id    (INT)
--         prod_qty      (INT)       -- 생산/입고 수량

-- TABLE : sales_txn
-- COLS  : txn_date, store_id, product_id, qty, net_amount

-- PURPOSE : 재고/생산/매출을 연결해 재고 회전율·커버리지 보는 템플릿
-- INPUT   : inventory_daily, production_daily, sales_txn
-- OUTPUT  : 상품·점포별 매출, 평균재고, 회전율, 재고일수
-- NOTE    : 기간(start_date, end_date)만 바꾸면 재사용 가능

WITH params AS (
    SELECT
          DATE '2025-01-01' AS start_date
        , DATE '2025-01-31' AS end_date
),

sales_agg AS (
    SELECT
          t.store_id
        , t.product_id
        , SUM(t.qty)        AS sales_qty
        , SUM(t.net_amount) AS sales_amt
    FROM sales_txn t
    CROSS JOIN params p
    WHERE t.txn_date BETWEEN p.start_date AND p.end_date
    GROUP BY t.store_id, t.product_id
),

stock_agg AS (
    -- 기간 내 일별 재고 평균
    SELECT
          i.store_id
        , i.product_id
        , AVG(i.stock_qty) AS avg_stock_qty
        , MAX(i.stock_qty) AS max_stock_qty
        , MIN(i.stock_qty) AS min_stock_qty
    FROM inventory_daily i
    CROSS JOIN params p
    WHERE i.snap_date BETWEEN p.start_date AND p.end_date
    GROUP BY i.store_id, i.product_id
),

prod_agg AS (
    -- 기간 내 생산/입고 수량
    SELECT
          p.product_id
        , SUM(p.prod_qty) AS prod_qty
    FROM production_daily p
    CROSS JOIN params prm
    WHERE p.prod_date BETWEEN prm.start_date AND prm.end_date
    GROUP BY p.product_id
),

combined AS (
    SELECT
          COALESCE(s.store_id, st.store_id)   AS store_id
        , COALESCE(s.product_id, st.product_id) AS product_id
        , COALESCE(s.sales_qty, 0)            AS sales_qty
        , COALESCE(s.sales_amt, 0)            AS sales_amt
        , COALESCE(st.avg_stock_qty, 0)       AS avg_stock_qty
        , COALESCE(st.max_stock_qty, 0)       AS max_stock_qty
        , COALESCE(st.min_stock_qty, 0)       AS min_stock_qty
        , COALESCE(p.prod_qty, 0)             AS prod_qty
    FROM sales_agg s
    FULL OUTER JOIN stock_agg st
      ON s.store_id   = st.store_id
     AND s.product_id = st.product_id
    LEFT JOIN prod_agg p
      ON COALESCE(s.product_id, st.product_id) = p.product_id
)

SELECT
      store_id
    , product_id
    , sales_qty
    , sales_amt
    , avg_stock_qty
    , prod_qty
    , CASE 
        WHEN avg_stock_qty = 0 THEN NULL
        ELSE sales_qty * 1.0 / avg_stock_qty
      END AS stock_turnover    -- 회전율 = 판매수량 / 평균재고
    , CASE 
        WHEN sales_qty = 0 THEN NULL
        ELSE avg_stock_qty * 1.0 / (sales_qty / 31.0)
      END AS days_of_inventory -- 재고일수(31일 기준 예시)
FROM combined
ORDER BY store_id, product_id;
