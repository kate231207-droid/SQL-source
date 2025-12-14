-- TABLE : campaign_master
-- COLS  : campaign_id    (INT)
--         campaign_name  (VARCHAR)
--         start_date     (DATE)
--         end_date       (DATE)
--         target_min_age (INT)
--         target_max_age (INT)
--         target_region  (VARCHAR)   -- NULL이면 전체

-- TABLE : campaign_contact
-- COLS  : campaign_id    (INT)
--         customer_id    (INT)
--         contact_date   (DATE)
--         channel        (VARCHAR)   -- 발송 채널(SMS, EMAIL 등)

-- TABLE : sales_txn, customer_dim  -- 앞에서 정의한 것과 동일

-- PURPOSE : 캠페인 대상자 추출 + AB 그룹 나누기 + 성과 집계 템플릿
-- INPUT   : campaign_master, campaign_contact, customer_dim, sales_txn
-- OUTPUT  : 그룹별 전환율, 객단가, 매출
-- NOTE    : 캠페인 ID, 효과 측정 기간만 바꿔서 재사용

WITH params AS (
    SELECT
          1001                 AS campaign_id      -- 분석할 캠페인 ID
        , DATE '2025-02-01'    AS kpi_start_date   -- 효과 측정 시작일
        , DATE '2025-02-28'    AS kpi_end_date     -- 효과 측정 종료일
),

cust_profile AS (
    SELECT
          c.customer_id
        , c.gender
        , c.region
        , FLOOR(EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM c.birth_date)) AS age
    FROM customer_dim c
),

target_base AS (
    -- 캠페인 타깃 조건(연령/지역 등)에 맞는 고객 선별
    SELECT
          cp.customer_id
        , cp.gender
        , cp.region
        , cp.age
    FROM params p
    JOIN campaign_master m
      ON p.campaign_id = m.campaign_id
    JOIN cust_profile cp
      ON cp.age BETWEEN m.target_min_age AND m.target_max_age
     AND (m.target_region IS NULL OR cp.region = m.target_region)
),

ab_group AS (
    -- 해시/난수로 A/B 그룹 나누기 (50:50 예시)
    SELECT
          t.customer_id
        , t.gender
        , t.region
        , t.age
        , CASE 
            WHEN MOD(ABS(HASH(t.customer_id)), 2) = 0 THEN 'A'
            ELSE 'B'
          END AS ab_group
    FROM target_base t
),

contacted AS (
    -- 실제로 캠페인 발송된 고객(처리 로그 기준)
    SELECT DISTINCT
          p.campaign_id
        , c.customer_id
    FROM params p
    JOIN campaign_contact c
      ON p.campaign_id = c.campaign_id
),

txn_kpi AS (
    -- KPI 기간 동안의 구매 실적
    SELECT
          t.customer_id
        , SUM(t.net_amount) AS kpi_sales
        , COUNT(*)          AS kpi_txn_cnt
    FROM sales_txn t
    CROSS JOIN params p
    WHERE t.txn_date BETWEEN p.kpi_start_date AND p.kpi_end_date
    GROUP BY t.customer_id
),

analysis_base AS (
    SELECT
          g.ab_group
        , g.customer_id
        , CASE WHEN ct.customer_id IS NOT NULL THEN 1 ELSE 0 END AS is_contacted
        , CASE WHEN tx.kpi_sales IS NOT NULL THEN 1 ELSE 0 END AS is_buyer
        , COALESCE(tx.kpi_sales, 0) AS kpi_sales
    FROM ab_group g
    LEFT JOIN contacted ct
           ON g.customer_id = ct.customer_id
    LEFT JOIN txn_kpi tx
           ON g.customer_id = tx.customer_id
)

SELECT
      ab_group
    , COUNT(*)                                   AS customers
    , SUM(is_contacted)                          AS contacted_cnt
    , SUM(is_buyer)                              AS buyer_cnt
    , CASE 
        WHEN SUM(is_contacted) = 0 THEN 0
        ELSE 1.0 * SUM(is_buyer) / SUM(is_contacted)
      END                                        AS conv_rate
    , SUM(kpi_sales)                             AS total_sales
    , CASE 
        WHEN SUM(is_buyer) = 0 THEN 0
        ELSE 1.0 * SUM(kpi_sales) / SUM(is_buyer)
      END                                        AS avg_sales_per_buyer
FROM analysis_base
GROUP BY ab_group
ORDER BY ab_group;