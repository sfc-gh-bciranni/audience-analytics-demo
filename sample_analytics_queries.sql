-- ================================================
-- MEDIA AGENCY AUDIENCE ANALYTICS SAMPLE QUERIES
-- ================================================
-- Comprehensive SQL queries demonstrating creative optimization 
-- and audience intelligence capabilities for media agency workflows

-- ================================================
-- CREATIVE PERFORMANCE ANALYTICS
-- ================================================

-- 1. TOP PERFORMING CREATIVES FOR A SPECIFIC AUDIENCE SEGMENT
-- Shows best-performing creatives for Fashion & Beauty enthusiasts
SELECT 
    cm.creative_id,
    cm.image_url,
    cm.creative_format,
    cm.content_type,
    cm.image_tags,
    cm.sentiment_score,
    SUM(cp.impressions) as total_impressions,
    SUM(cp.clicks) as total_clicks,
    SUM(cp.conversions) as total_conversions,
    AVG(cp.CTR) as avg_ctr,
    AVG(cp.ROI) as avg_roi,
    SUM(cp.cost) as total_cost
FROM creative_metadata cm
JOIN campaign_performance cp ON cm.creative_id = cp.creative_id
JOIN audience_segments aseg ON cp.segment_id = aseg.segment_id
WHERE aseg.primary_interest = 'Fashion & Beauty'
GROUP BY cm.creative_id, cm.image_url, cm.creative_format, cm.content_type, cm.image_tags, cm.sentiment_score
ORDER BY avg_roi DESC, avg_ctr DESC
LIMIT 20;

-- 2. CREATIVE PERFORMANCE BY SENTIMENT SCORE
-- Analyze how creative sentiment impacts performance
SELECT 
    CASE 
        WHEN cm.sentiment_score >= 0.5 THEN 'Highly Positive'
        WHEN cm.sentiment_score >= 0.1 THEN 'Positive'
        WHEN cm.sentiment_score >= -0.1 THEN 'Neutral'
        WHEN cm.sentiment_score >= -0.5 THEN 'Negative'
        ELSE 'Highly Negative'
    END as sentiment_category,
    COUNT(DISTINCT cm.creative_id) as creative_count,
    AVG(cm.sentiment_score) as avg_sentiment,
    SUM(cp.impressions) as total_impressions,
    AVG(cp.CTR) as avg_ctr,
    AVG(cp.ROI) as avg_roi,
    SUM(cp.conversions) as total_conversions
FROM creative_metadata cm
LEFT JOIN campaign_performance cp ON cm.creative_id = cp.creative_id
GROUP BY sentiment_category
ORDER BY avg_roi DESC;

-- 3. FILTER IMAGES BY TAG AND DISPLAY WITH CAMPAIGN STATS
-- Find all lifestyle creatives with performance metrics
SELECT 
    cm.creative_id,
    cm.image_url,
    cm.creative_format,
    cm.content_type,
    cm.image_tags,
    cm.campaign_id,
    COUNT(DISTINCT cp.segment_id) as segments_targeted,
    SUM(cp.impressions) as campaign_impressions,
    SUM(cp.clicks) as campaign_clicks,
    AVG(cp.CTR) as avg_campaign_ctr,
    AVG(cp.ROI) as avg_campaign_roi
FROM creative_metadata cm
LEFT JOIN campaign_performance cp ON cm.creative_id = cp.creative_id
WHERE cm.image_tags LIKE '%lifestyle%' 
   OR cm.content_type = 'Lifestyle'
GROUP BY cm.creative_id, cm.image_url, cm.creative_format, cm.content_type, cm.image_tags, cm.campaign_id
ORDER BY avg_campaign_roi DESC;

-- ================================================
-- AUDIENCE SEGMENTATION ANALYTICS  
-- ================================================

-- 4. AUDIENCE SEGMENT PERFORMANCE ANALYSIS
-- Compare performance across different audience segments
SELECT 
    aseg.segment_name,
    aseg.primary_interest,
    aseg.secondary_interest,
    COUNT(DISTINCT aseg.audience_id) as audience_count,
    COUNT(DISTINCT cp.creative_id) as creatives_tested,
    SUM(cp.impressions) as total_impressions,
    SUM(cp.clicks) as total_clicks,
    SUM(cp.conversions) as total_conversions,
    AVG(cp.CTR) as avg_ctr,
    AVG(cp.ROI) as avg_roi,
    SUM(cp.cost) as total_spend
FROM audience_segments aseg
LEFT JOIN campaign_performance cp ON aseg.segment_id = cp.segment_id
GROUP BY aseg.segment_name, aseg.primary_interest, aseg.secondary_interest
HAVING total_impressions > 0
ORDER BY avg_roi DESC, total_conversions DESC
LIMIT 25;

-- 5. CROSS-CHANNEL AUDIENCE ENGAGEMENT
-- Analyze how different demographics engage across media channels
SELECT 
    ad.age_group,
    ad.gender,
    mce.channel_type,
    COUNT(DISTINCT ad.audience_id) as audience_count,
    AVG(mce.impressions) as avg_impressions,
    AVG(mce.reach) as avg_reach,
    AVG(mce.frequency) as avg_frequency,
    AVG(mce.engagement_rate) as avg_engagement_rate
FROM audience_demographics ad
JOIN media_channel_engagement mce ON ad.audience_id = mce.audience_id
GROUP BY ad.age_group, ad.gender, mce.channel_type
ORDER BY ad.age_group, avg_engagement_rate DESC;

-- 6. LOOKALIKE SEGMENT PERFORMANCE COMPARISON
-- Compare original vs lookalike segment performance
SELECT 
    aseg.primary_interest,
    aseg.lookalike_segment_flag,
    COUNT(DISTINCT aseg.segment_id) as segment_count,
    COUNT(DISTINCT aseg.audience_id) as audience_count,
    AVG(cp.CTR) as avg_ctr,
    AVG(cp.ROI) as avg_roi,
    SUM(cp.conversions) as total_conversions,
    SUM(cp.cost) as total_cost
FROM audience_segments aseg
LEFT JOIN campaign_performance cp ON aseg.segment_id = cp.segment_id
GROUP BY aseg.primary_interest, aseg.lookalike_segment_flag
HAVING total_cost > 0
ORDER BY aseg.primary_interest, aseg.lookalike_segment_flag;

-- ================================================
-- CREATIVE FORMAT & CONTENT OPTIMIZATION
-- ================================================

-- 7. CREATIVE FORMAT PERFORMANCE BY CHANNEL
-- Understand which creative formats work best on each channel
SELECT 
    cp.media_channel,
    cm.creative_format,
    COUNT(DISTINCT cm.creative_id) as creative_count,
    SUM(cp.impressions) as total_impressions,
    AVG(cp.CTR) as avg_ctr,
    AVG(cp.ROI) as avg_roi,
    SUM(cp.conversions) as total_conversions
FROM campaign_performance cp
JOIN creative_metadata cm ON cp.creative_id = cm.creative_id
GROUP BY cp.media_channel, cm.creative_format
ORDER BY cp.media_channel, avg_roi DESC;

-- 8. CONTENT TYPE EFFECTIVENESS BY DEMOGRAPHIC
-- See which content types resonate with different age groups
SELECT 
    ad.age_group,
    cm.content_type,
    COUNT(DISTINCT cm.creative_id) as creative_count,
    AVG(cp.CTR) as avg_ctr,
    AVG(cp.ROI) as avg_roi,
    SUM(cp.conversions) as total_conversions,
    AVG(cm.sentiment_score) as avg_sentiment
FROM audience_demographics ad
JOIN audience_segments aseg ON ad.audience_id = aseg.audience_id
JOIN campaign_performance cp ON aseg.segment_id = cp.segment_id
JOIN creative_metadata cm ON cp.creative_id = cm.creative_id
GROUP BY ad.age_group, cm.content_type
HAVING creative_count >= 3
ORDER BY ad.age_group, avg_roi DESC;

-- ================================================
-- ATTRIBUTION & JOURNEY ANALYSIS
-- ================================================

-- 9. CROSS-CHANNEL ATTRIBUTION ANALYSIS
-- Track customer journey across touchpoints
SELECT 
    ae.campaign_id,
    ae.audience_id,
    COUNT(DISTINCT ae.media_channel) as channels_touched,
    COUNT(ae.attribution_id) as total_touchpoints,
    STRING_AGG(DISTINCT ae.media_channel, ' → ') as channel_journey,
    STRING_AGG(DISTINCT ae.touchpoint_type, ' → ') as touchpoint_journey,
    AVG(ae.attribution_percent) as avg_attribution,
    MAX(ae.timestamp) as last_touchpoint,
    MIN(ae.timestamp) as first_touchpoint
FROM attribution_events ae
GROUP BY ae.campaign_id, ae.audience_id
HAVING channels_touched > 1
ORDER BY channels_touched DESC, total_touchpoints DESC
LIMIT 50;

-- 10. ATTRIBUTION BY CHANNEL SEQUENCE
-- Understand the impact of channel order in customer journeys
WITH journey_analysis AS (
    SELECT 
        campaign_id,
        audience_id,
        media_channel,
        ROW_NUMBER() OVER (PARTITION BY campaign_id, audience_id ORDER BY timestamp) as step_number,
        attribution_percent
    FROM attribution_events
    WHERE touchpoint_type IN ('View', 'Click', 'Conversion')
)
SELECT 
    step_number as journey_step,
    media_channel,
    COUNT(*) as touchpoint_count,
    AVG(attribution_percent) as avg_attribution_value,
    COUNT(DISTINCT campaign_id) as campaigns_involved
FROM journey_analysis
GROUP BY step_number, media_channel
ORDER BY step_number, avg_attribution_value DESC;

-- ================================================
-- PRIVACY & COMPLIANCE REPORTING
-- ================================================

-- 11. CONSENT STATUS IMPACT ON PERFORMANCE
-- Analyze performance differences based on privacy consent
SELECT 
    cp_priv.consent_status,
    cp_priv.PII_flag,
    COUNT(DISTINCT ad.audience_id) as audience_count,
    AVG(mce.engagement_rate) as avg_engagement_rate,
    COUNT(DISTINCT aseg.segment_id) as segments_available,
    COALESCE(AVG(perf.CTR), 0) as avg_ctr,
    COALESCE(AVG(perf.ROI), 0) as avg_roi
FROM consent_privacy cp_priv
JOIN audience_demographics ad ON cp_priv.audience_id = ad.audience_id
LEFT JOIN media_channel_engagement mce ON ad.audience_id = mce.audience_id
LEFT JOIN audience_segments aseg ON ad.audience_id = aseg.audience_id
LEFT JOIN campaign_performance perf ON aseg.segment_id = perf.segment_id
GROUP BY cp_priv.consent_status, cp_priv.PII_flag
ORDER BY avg_engagement_rate DESC;

-- ================================================
-- ADVANCED ANALYTICS & INSIGHTS
-- ================================================

-- 12. CREATIVE ROTATION OPTIMIZATION
-- Find the optimal number of creatives per campaign
SELECT 
    cm.campaign_id,
    COUNT(DISTINCT cm.creative_id) as creative_count,
    AVG(cm.sentiment_score) as avg_creative_sentiment,
    SUM(cp.impressions) as total_impressions,
    AVG(cp.CTR) as avg_ctr,
    AVG(cp.ROI) as avg_roi,
    SUM(cp.conversions) as total_conversions,
    SUM(cp.cost) as total_cost
FROM creative_metadata cm
LEFT JOIN campaign_performance cp ON cm.creative_id = cp.creative_id
GROUP BY cm.campaign_id
HAVING creative_count > 0
ORDER BY avg_roi DESC;

-- 13. SEASONAL PERFORMANCE TRENDS
-- Analyze performance patterns by time periods
SELECT 
    EXTRACT(MONTH FROM ae.timestamp) as month,
    EXTRACT(YEAR FROM ae.timestamp) as year,
    COUNT(DISTINCT ae.campaign_id) as active_campaigns,
    COUNT(DISTINCT ae.audience_id) as active_audiences,
    AVG(ae.attribution_percent) as avg_attribution,
    COUNT(ae.attribution_id) as total_events
FROM attribution_events ae
GROUP BY EXTRACT(MONTH FROM ae.timestamp), EXTRACT(YEAR FROM ae.timestamp)
ORDER BY year, month;

-- 14. HIGH-VALUE AUDIENCE IDENTIFICATION
-- Identify audience segments with highest lifetime value
SELECT 
    ad.audience_id,
    ad.age_group,
    ad.household_income,
    ad.state,
    COUNT(DISTINCT aseg.segment_id) as segment_memberships,
    COUNT(DISTINCT cp.campaign_id) as campaigns_participated,
    SUM(cp.conversions) as total_conversions,
    AVG(cp.ROI) as avg_roi_contributed,
    SUM(cp.cost) as total_media_cost
FROM audience_demographics ad
JOIN audience_segments aseg ON ad.audience_id = aseg.audience_id
JOIN campaign_performance cp ON aseg.segment_id = cp.segment_id
GROUP BY ad.audience_id, ad.age_group, ad.household_income, ad.state
HAVING total_conversions > 5
ORDER BY total_conversions DESC, avg_roi_contributed DESC
LIMIT 100;

-- 15. CREATIVE A/B TEST RESULTS
-- Compare similar creatives to identify winning elements
SELECT 
    cm1.content_type,
    cm1.creative_format,
    'Creative A' as version,
    cm1.creative_id,
    cm1.sentiment_score,
    AVG(cp1.CTR) as avg_ctr,
    AVG(cp1.ROI) as avg_roi,
    SUM(cp1.conversions) as total_conversions
FROM creative_metadata cm1
JOIN campaign_performance cp1 ON cm1.creative_id = cp1.creative_id
WHERE cm1.campaign_id IN (
    SELECT campaign_id 
    FROM creative_metadata 
    GROUP BY campaign_id 
    HAVING COUNT(DISTINCT creative_id) >= 2
)
GROUP BY cm1.content_type, cm1.creative_format, cm1.creative_id, cm1.sentiment_score

UNION ALL

SELECT 
    cm2.content_type,
    cm2.creative_format,
    'Creative B' as version,
    cm2.creative_id,
    cm2.sentiment_score,
    AVG(cp2.CTR) as avg_ctr,
    AVG(cp2.ROI) as avg_roi,
    SUM(cp2.conversions) as total_conversions
FROM creative_metadata cm2
JOIN campaign_performance cp2 ON cm2.creative_id = cp2.creative_id
WHERE cm2.campaign_id IN (
    SELECT campaign_id 
    FROM creative_metadata 
    GROUP BY campaign_id 
    HAVING COUNT(DISTINCT creative_id) >= 2
)
GROUP BY cm2.content_type, cm2.creative_format, cm2.creative_id, cm2.sentiment_score
ORDER BY content_type, creative_format, avg_roi DESC;

-- ================================================
-- REPORTING VIEWS FOR DASHBOARDS
-- ================================================

-- 16. EXECUTIVE SUMMARY REPORT
-- High-level KPIs for leadership reporting
SELECT 
    'Total Audiences' as metric,
    COUNT(DISTINCT ad.audience_id) as value,
    '' as details
FROM audience_demographics ad

UNION ALL

SELECT 
    'Total Campaigns' as metric,
    COUNT(DISTINCT cp.campaign_id) as value,
    '' as details
FROM campaign_performance cp

UNION ALL

SELECT 
    'Total Creatives' as metric,
    COUNT(DISTINCT cm.creative_id) as value,
    CONCAT(COUNT(CASE WHEN cm.audit_status = 'Approved' THEN 1 END), ' approved') as details
FROM creative_metadata cm

UNION ALL

SELECT 
    'Average ROI' as metric,
    ROUND(AVG(cp.ROI), 2) as value,
    'Across all campaigns' as details
FROM campaign_performance cp

UNION ALL

SELECT 
    'Total Conversions' as metric,
    SUM(cp.conversions) as value,
    CONCAT('$', ROUND(SUM(cp.cost), 0), ' total spend') as details
FROM campaign_performance cp;

-- ================================================
-- QUERY EXECUTION NOTES
-- ================================================

/*
USAGE INSTRUCTIONS:

1. Load your data using the provided CSV files and database schema
2. Execute queries individually or in groups based on your analysis needs
3. Modify WHERE clauses to filter for specific campaigns, audiences, or time periods
4. Use LIMIT clauses to control result set sizes for initial exploration
5. Customize date ranges in temporal queries for specific reporting periods

PERFORMANCE TIPS:

- Queries are optimized for the created indexes in the schema
- For large datasets, consider adding date range filters
- Use EXPLAIN to analyze query execution plans
- Consider creating materialized views for frequently run analytical queries

CUSTOMIZATION:

- Replace hardcoded values (like 'Fashion & Beauty') with parameters
- Adjust aggregation levels based on reporting requirements  
- Add additional filtering for geographic or demographic constraints
- Extend attribution analysis for more complex customer journey mapping
*/
