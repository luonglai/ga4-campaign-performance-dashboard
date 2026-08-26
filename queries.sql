-- ============================================================
-- GA4 Campaign Performance Dashboard — Extraction Queries
-- Dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Source: Google Merchandise Store GA4 export (public sample)
-- ============================================================
-- Run the schema check below FIRST to confirm field names
-- haven't shifted before running the full queries.

-- --------------------------------------------------------------
-- 0. Schema check — run this first
-- --------------------------------------------------------------
SELECT *
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201101'
LIMIT 5;


-- --------------------------------------------------------------
-- 1. Channel-level performance
-- Sessions, purchases, and revenue by traffic source
-- NOTE: traffic_source is user-level first-touch attribution,
-- not session-level. Document this limitation in the README.
-- --------------------------------------------------------------
SELECT
  traffic_source.medium AS channel_medium,
  traffic_source.source AS channel_source,
  COUNT(DISTINCT CONCAT(
    user_pseudo_id,
    CAST((SELECT value.int_value FROM UNNEST(event_params)
          WHERE key = 'ga_session_id') AS STRING)
  )) AS sessions,
  COUNTIF(event_name = 'purchase') AS purchases,
  ROUND(SUM(ecommerce.purchase_revenue_in_usd), 2) AS revenue_usd
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY channel_medium, channel_source
ORDER BY revenue_usd DESC;


-- --------------------------------------------------------------
-- 2. Funnel breakdown
-- Distinct sessions reaching each funnel stage
-- --------------------------------------------------------------
WITH funnel_events AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params)
     WHERE key = 'ga_session_id') AS session_id,
    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
)
SELECT
  CASE event_name
    WHEN 'view_item'       THEN 1
    WHEN 'add_to_cart'     THEN 2
    WHEN 'begin_checkout'  THEN 3
    WHEN 'purchase'        THEN 4
  END AS funnel_stage,
  event_name,
  COUNT(DISTINCT CONCAT(user_pseudo_id, CAST(session_id AS STRING))) AS sessions_reached
FROM funnel_events
GROUP BY funnel_stage, event_name
ORDER BY funnel_stage;


-- --------------------------------------------------------------
-- 3. Revenue trend over time, by channel
-- --------------------------------------------------------------
SELECT
  PARSE_DATE('%Y%m%d', event_date) AS date,
  traffic_source.medium AS channel_medium,
  COUNTIF(event_name = 'purchase') AS purchases,
  ROUND(SUM(ecommerce.purchase_revenue_in_usd), 2) AS revenue_usd
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  AND event_name = 'purchase'
GROUP BY date, channel_medium
ORDER BY date, channel_medium;
