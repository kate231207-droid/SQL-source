-- TABLE : customer_dim
-- COLS  : customer_id    (INT)
--         gender         (VARCHAR)   -- 'M','F' 등
--         birth_date     (DATE)
--         region         (VARCHAR)   -- 거주 지역
--         reg_channel    (VARCHAR)   -- 가입 채널(웹, 매장 등)
--         join_date      (DATE)      -- 첫 가입일

-- TABLE : sales_txn   -- 앞에서 쓴 것과 동일
-- COLS  : txn_date, store_id, channel, customer_id, product_id, qty, net_amount



-- PURPOSE : 고객 기본 프로필 + RFM 지표 산출 템플릿
-- INPUT   : customer_dim, sales_txn
-- OUTPUT  : customer_id, 성별/연령대/지역, R/F/M, 최근 구매일 등
-- NOTE    : 기준일(@as_of_date)과 기간 필터만 상황에 맞게 수정

-- 기준일(분석 기준 날짜) 가정
WITH params AS (
    SELECT DATE '2025-01-31' AS as_of_date
),

cust_base AS (
    SELECT
          c.customer_id
        , c.gender
        , c.birth_date
        , c.region
        , c.reg_channel
        , c.join_date
        , FLOOR( EXTRACT(YEAR FROM (SELECT as_of_date FROM params))
               - EXTRACT(YEAR FROM c.birth_date) ) AS age
    FROM customer_dim c
),

txn_filtered AS (
    SELECT
          t.customer_id
        , t.txn_date
        , t.net_amount
    FROM sales_txn t
    CROSS JOIN params p
    WHERE 1=1
      -- 기준일 이전 거래만 사용
      AND t.txn_date <= p.as_of_date
      -- 분석 기간: 최근 1년 예시 (필요시 수정)
      AND t.txn_date >= p.as_of_date - INTERVAL '365' DAY
      -- 온라인 채널만 보려면 예시
      -- AND t.channel = 'ONLINE'
),

rfm AS (
    SELECT
          x.customer_id
        -- R(Recency): 마지막 구매 후 경과일
        , MIN(DATE_PART('day', p.as_of_date - x.last_txn_date)) AS R_days
        -- F(Frequency): 기간 내 구매 횟수
        , SUM(x.txn_cnt)                                      AS F_cnt
        -- M(Monetary): 기간 내 총 매출
        , SUM(x.amount_sum)                                   AS M_amt
    FROM (
        SELECT
              t.customer_id
            , MAX(t.txn_date)              AS last_txn_date
            , COUNT(*)                     AS txn_cnt
            , SUM(t.net_amount)            AS amount_sum
        FROM txn_filtered t
        GROUP BY t.customer_id
    ) x
    CROSS JOIN params p
    GROUP BY x.customer_id, p.as_of_date
),

profile_final AS (
    SELECT
          cb.customer_id
        , cb.gender
        , cb.region
        , cb.reg_channel
        , cb.age
        , CASE 
            WHEN cb.age < 20 THEN '10s'
            WHEN cb.age BETWEEN 20 AND 29 THEN '20s'
            WHEN cb.age BETWEEN 30 AND 39 THEN '30s'
            WHEN cb.age BETWEEN 40 AND 49 THEN '40s'
            ELSE '50+'
          END AS age_band
        , r.R_days
        , r.F_cnt
        , r.M_amt
    FROM cust_base cb
    LEFT JOIN rfm r
           ON cb.customer_id = r.customer_id
)

SELECT *
FROM profile_final
ORDER BY age_band, region, M_amt DESC;
