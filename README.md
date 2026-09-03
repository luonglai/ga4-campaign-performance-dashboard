# Campaign Performance & Funnel Dashboard (GA4 → Tableau)

## Business question
Which acquisition channels are driving the most efficient revenue for the
Google Merchandise Store, and at which stage of the purchase funnel are we
losing the most users?

## Approach
1. Extracted channel, funnel, and revenue-trend data via SQL from Google's
   public GA4 export sample (`bigquery-public-data.ga4_obfuscated_sample_ecommerce`)
   in BigQuery — see `queries.sql`.
2. Exported results to CSV and built an interactive dashboard in Tableau Public
   covering channel performance, funnel drop-off, and revenue trend by channel.
3. Grouped low-value/unattributed traffic sources (`(none)`, `(data deleted)`,
   `<Other>`) into a single "Other/Unattributed" category for a cleaner read,
   and cross-filtered Channel Performance against Revenue Trend so a viewer
   can isolate any one channel's trend on demand.
## Key metrics

| Metric | Definition |
|---|---|
| **Total Revenue** | Sum of GA4 `purchase_revenue_in_usd` across all sessions in the sample period (6 Nov 2020 – 4 Feb 2021). |
| **Sessions (All Channels)** | Distinct GA4 sessions in the sample period, regardless of which funnel stage they reached. |
| **View-to-Purchase Conversion** | Sessions reaching the `purchase` event ÷ sessions reaching the `view_item` event, expressed as a percentage. Measures overall funnel efficiency, not per-channel conversion. |
| **Channel Medium (group)** | GA4's raw `traffic_source.medium` field, grouped into four buckets for readability: `cpc` (paid search), `organic` (organic search), `referral` (referring sites), and `other` (remaining/unattributed mediums — see Data & Limitations). |
| **Sessions Reached (funnel stage)** | Count of distinct sessions that logged at least one instance of a given GA4 ecommerce event (`view_item`, `add_to_cart`, `begin_checkout`, `purchase`). |
| **Stage-to-stage drop-off** | Percentage decrease in Sessions Reached between two consecutive funnel stages; used to identify where the largest share of users is lost. |

## Data & limitations
- Data source: Google's public GA4 sample export (Google Merchandise Store),
  November 2020 – early February 2021.
- **Attribution limitation:** `traffic_source` in this export reflects each
  user's *first-touch* acquisition channel, not session-level attribution, so
  GA4's session-level `collected_traffic_source` field isn't populated in this
  sample. Channel performance here should be read as "channel that first
  brought the user," not "channel that drove this specific session's revenue."
  A production version would need session-level attribution or a proper
  multi-touch model.
- A small number of rows (3 in the channel-performance extract) carry null
  values on the underlying attribution fields, which is consistent with the same
  redacted/unattributed pattern already captured by the "Other/Unattributed"
  grouping above, not a separate data-quality issue.

## Key findings
- **Organic is the strongest revenue channel**, with referral close behind.
  Paid (CPC) trails both by a wide margin. See Channel Performance.
- **The funnel has a steep overall drop-off**: of 77,020 sessions that
  reached `view_item`, only 4,848 completed `purchase`, making a 6.3%
  view-to-purchase conversion rate (a ~93.7% drop-off). The single steepest
  stage-to-stage loss is between `view_item` and `add_to_cart`, well before
  checkout.
- **Revenue is highly volatile day-to-day** rather than trending smoothly with
  sharp spikes recur through November and January, with a sustained lull
  through most of December.

## Recommendation
Because the largest single loss in the funnel happens between `view_item` and
`add_to_cart` instead of at checkout, the highest-leverage next step is
investigating friction at that specific stage (product page clarity, pricing
or shipping-cost visibility, or a possible tracking/technical leak) rather
than spending further on broad top-of-funnel acquisition. On the channel
side, organic and referral are the highest-revenue channels and would be the
first candidates to protect or grow if this were a live budget decision,
though a full ROI comparison would need per-channel cost data this export
doesn't include. Any channel-based budget decision should also be validated
against session-level attribution before being acted on with confidence,
given the first-touch limitation noted above.

## How to reproduce
1. Run `queries.sql` against `bigquery-public-data.ga4_obfuscated_sample_ecommerce`
   in BigQuery (free sandbox tier).
2. Export each query result to CSV.
3. Open `dashboard.twbx` in Tableau Public / Tableau Desktop, or rebuild from
   the CSVs using the same three views (channel performance, funnel, revenue trend).

## Links
- Live dashboard: https://public.tableau.com/app/profile/luong.lai/viz/CampaignPerformanceFunnelDashboard/CampaignPerformanceFunnelDashboard
- Repo: https://github.com/luonglai/ga4-campaign-performance-dashboard
