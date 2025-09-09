-- ================================================
-- Media Audience Analytics Database Schema
-- ================================================
-- This script creates the complete database schema for the audience exploration tool
-- Designed to support creative optimization and audience intelligence workflows

-- Drop existing tables (in reverse dependency order)
DROP TABLE IF EXISTS attribution_events;
DROP TABLE IF EXISTS campaign_performance;
DROP TABLE IF EXISTS consent_privacy;
DROP TABLE IF EXISTS media_channel_engagement;
DROP TABLE IF EXISTS creative_metadata;
DROP TABLE IF EXISTS audience_segments;
DROP TABLE IF EXISTS audience_demographics;

-- ================================================
-- 1. AUDIENCE DEMOGRAPHICS (Primary table)
-- ================================================
CREATE TABLE audience_demographics (
    audience_id VARCHAR(10) PRIMARY KEY,
    age_group VARCHAR(10) NOT NULL,
    gender VARCHAR(20) NOT NULL,
    state VARCHAR(2) NOT NULL,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(10) NOT NULL DEFAULT 'USA',
    household_income VARCHAR(15) NOT NULL,
    education_level VARCHAR(20) NOT NULL,
    ethnicity VARCHAR(30) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_demographics_age (age_group),
    INDEX idx_demographics_state (state),
    INDEX idx_demographics_income (household_income)
);

-- ================================================
-- 2. AUDIENCE SEGMENTS (Many-to-Many with audiences)
-- ================================================
CREATE TABLE audience_segments (
    segment_id VARCHAR(10) PRIMARY KEY,
    audience_id VARCHAR(10) NOT NULL,
    segment_name VARCHAR(100) NOT NULL,
    primary_interest VARCHAR(50) NOT NULL,
    secondary_interest VARCHAR(50) NOT NULL,
    lookalike_segment_flag BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (audience_id) REFERENCES audience_demographics(audience_id) ON DELETE CASCADE,
    INDEX idx_segments_audience (audience_id),
    INDEX idx_segments_primary_interest (primary_interest),
    INDEX idx_segments_lookalike (lookalike_segment_flag)
);

-- ================================================
-- 3. CREATIVE METADATA (Linked to campaigns)
-- ================================================
CREATE TABLE creative_metadata (
    creative_id VARCHAR(10) PRIMARY KEY,
    image_url VARCHAR(200) NOT NULL,
    creative_format VARCHAR(20) NOT NULL,
    content_type VARCHAR(30) NOT NULL,
    image_tags TEXT NOT NULL,
    sentiment_score DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    audit_status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    created_date DATE NOT NULL,
    campaign_id VARCHAR(10) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_creative_format (creative_format),
    INDEX idx_creative_content_type (content_type),
    INDEX idx_creative_campaign (campaign_id),
    INDEX idx_creative_sentiment (sentiment_score),
    INDEX idx_creative_audit_status (audit_status),
    FULLTEXT idx_creative_tags (image_tags)
);

-- ================================================
-- 4. MEDIA CHANNEL ENGAGEMENT (Audience channel behavior)
-- ================================================
CREATE TABLE media_channel_engagement (
    engagement_id VARCHAR(10) PRIMARY KEY,
    audience_id VARCHAR(10) NOT NULL,
    channel_type VARCHAR(20) NOT NULL,
    impressions INT NOT NULL DEFAULT 0,
    reach INT NOT NULL DEFAULT 0,
    frequency DECIMAL(6,2) NOT NULL DEFAULT 1.00,
    engagement_rate DECIMAL(6,4) NOT NULL DEFAULT 0.0000,
    measurement_date DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (audience_id) REFERENCES audience_demographics(audience_id) ON DELETE CASCADE,
    INDEX idx_engagement_audience (audience_id),
    INDEX idx_engagement_channel (channel_type),
    INDEX idx_engagement_rate (engagement_rate)
);

-- ================================================
-- 5. CAMPAIGN PERFORMANCE (Central analytics table)
-- ================================================
CREATE TABLE campaign_performance (
    performance_id VARCHAR(10) PRIMARY KEY,
    campaign_id VARCHAR(10) NOT NULL,
    segment_id VARCHAR(10) NOT NULL,
    creative_id VARCHAR(10) NOT NULL,
    media_channel VARCHAR(20) NOT NULL,
    impressions INT NOT NULL DEFAULT 0,
    clicks INT NOT NULL DEFAULT 0,
    conversions INT NOT NULL DEFAULT 0,
    cost DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    ROI DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    CTR DECIMAL(6,4) NOT NULL DEFAULT 0.0000,
    performance_date DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (segment_id) REFERENCES audience_segments(segment_id) ON DELETE CASCADE,
    FOREIGN KEY (creative_id) REFERENCES creative_metadata(creative_id) ON DELETE CASCADE,
    INDEX idx_performance_campaign (campaign_id),
    INDEX idx_performance_segment (segment_id),
    INDEX idx_performance_creative (creative_id),
    INDEX idx_performance_channel (media_channel),
    INDEX idx_performance_ctr (CTR),
    INDEX idx_performance_roi (ROI)
);

-- ================================================
-- 6. ATTRIBUTION EVENTS (Event-level tracking)
-- ================================================
CREATE TABLE attribution_events (
    attribution_id VARCHAR(10) PRIMARY KEY,
    campaign_id VARCHAR(10) NOT NULL,
    audience_id VARCHAR(10) NOT NULL,
    media_channel VARCHAR(20) NOT NULL,
    timestamp DATETIME NOT NULL,
    touchpoint_type VARCHAR(20) NOT NULL,
    attribution_percent DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    benchmark DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (audience_id) REFERENCES audience_demographics(audience_id) ON DELETE CASCADE,
    INDEX idx_attribution_campaign (campaign_id),
    INDEX idx_attribution_audience (audience_id),
    INDEX idx_attribution_timestamp (timestamp),
    INDEX idx_attribution_touchpoint (touchpoint_type),
    INDEX idx_attribution_channel (media_channel)
);

-- ================================================
-- 7. CONSENT PRIVACY (GDPR/CCPA compliance)
-- ================================================
CREATE TABLE consent_privacy (
    consent_id VARCHAR(10) PRIMARY KEY,
    audience_id VARCHAR(10) NOT NULL UNIQUE,
    consent_status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    PII_flag BOOLEAN DEFAULT FALSE,
    privacy_signal_timestamp DATETIME NOT NULL,
    last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (audience_id) REFERENCES audience_demographics(audience_id) ON DELETE CASCADE,
    INDEX idx_consent_status (consent_status),
    INDEX idx_consent_pii (PII_flag),
    INDEX idx_consent_timestamp (privacy_signal_timestamp)
);

-- ================================================
-- VIEWS FOR COMMON ANALYTICS QUERIES
-- ================================================

-- Comprehensive audience performance view
CREATE VIEW audience_performance_summary AS
SELECT 
    ad.audience_id,
    ad.age_group,
    ad.gender,
    ad.state,
    ad.household_income,
    COUNT(DISTINCT cp.campaign_id) as total_campaigns,
    COUNT(DISTINCT cp.creative_id) as total_creatives,
    SUM(cp.impressions) as total_impressions,
    SUM(cp.clicks) as total_clicks,
    SUM(cp.conversions) as total_conversions,
    SUM(cp.cost) as total_cost,
    AVG(cp.CTR) as avg_ctr,
    AVG(cp.ROI) as avg_roi
FROM audience_demographics ad
JOIN audience_segments aseg ON ad.audience_id = aseg.audience_id
JOIN campaign_performance cp ON aseg.segment_id = cp.segment_id
GROUP BY ad.audience_id, ad.age_group, ad.gender, ad.state, ad.household_income;

-- Creative performance with metadata view
CREATE VIEW creative_performance_analysis AS
SELECT 
    cm.creative_id,
    cm.creative_format,
    cm.content_type,
    cm.image_tags,
    cm.sentiment_score,
    cm.audit_status,
    COUNT(DISTINCT cp.campaign_id) as campaigns_used,
    SUM(cp.impressions) as total_impressions,
    SUM(cp.clicks) as total_clicks,
    SUM(cp.conversions) as total_conversions,
    AVG(cp.CTR) as avg_ctr,
    AVG(cp.ROI) as avg_roi,
    SUM(cp.cost) as total_cost
FROM creative_metadata cm
LEFT JOIN campaign_performance cp ON cm.creative_id = cp.creative_id
GROUP BY cm.creative_id, cm.creative_format, cm.content_type, cm.image_tags, cm.sentiment_score, cm.audit_status;

-- Channel engagement summary
CREATE VIEW channel_engagement_summary AS
SELECT 
    mce.channel_type,
    COUNT(DISTINCT mce.audience_id) as unique_audiences,
    SUM(mce.impressions) as total_impressions,
    SUM(mce.reach) as total_reach,
    AVG(mce.frequency) as avg_frequency,
    AVG(mce.engagement_rate) as avg_engagement_rate
FROM media_channel_engagement mce
GROUP BY mce.channel_type
ORDER BY avg_engagement_rate DESC;

-- ================================================
-- DATA VALIDATION CONSTRAINTS
-- ================================================

-- Ensure CTR is calculated correctly where clicks > 0
ALTER TABLE campaign_performance 
ADD CONSTRAINT chk_ctr_valid 
CHECK (clicks = 0 OR CTR = clicks/impressions OR CTR BETWEEN 0 AND 1);

-- Ensure sentiment scores are within valid range
ALTER TABLE creative_metadata 
ADD CONSTRAINT chk_sentiment_range 
CHECK (sentiment_score BETWEEN -1.00 AND 1.00);

-- Ensure engagement rates are valid percentages
ALTER TABLE media_channel_engagement 
ADD CONSTRAINT chk_engagement_rate_valid 
CHECK (engagement_rate BETWEEN 0.0000 AND 1.0000);

-- ================================================
-- SAMPLE INDEXES FOR PERFORMANCE OPTIMIZATION
-- ================================================

-- Composite indexes for common query patterns
CREATE INDEX idx_performance_campaign_creative ON campaign_performance(campaign_id, creative_id);
CREATE INDEX idx_performance_segment_channel ON campaign_performance(segment_id, media_channel);
CREATE INDEX idx_segments_audience_interest ON audience_segments(audience_id, primary_interest);
CREATE INDEX idx_attribution_campaign_audience ON attribution_events(campaign_id, audience_id);

-- ================================================
-- TRIGGERS FOR DATA CONSISTENCY
-- ================================================

-- Update performance metrics when new records are added
DELIMITER $$
CREATE TRIGGER update_ctr_after_insert
    BEFORE INSERT ON campaign_performance
    FOR EACH ROW
BEGIN
    IF NEW.impressions > 0 THEN
        SET NEW.CTR = NEW.clicks / NEW.impressions;
    END IF;
END$$

CREATE TRIGGER update_ctr_after_update
    BEFORE UPDATE ON campaign_performance
    FOR EACH ROW
BEGIN
    IF NEW.impressions > 0 THEN
        SET NEW.CTR = NEW.clicks / NEW.impressions;
    END IF;
END$$
DELIMITER ;

-- ================================================
-- COMMENTS AND DOCUMENTATION
-- ================================================

ALTER TABLE audience_demographics COMMENT = 'Primary audience demographic data for targeting and segmentation';
ALTER TABLE audience_segments COMMENT = 'Multi-dimensional audience segments with interest-based classifications';
ALTER TABLE creative_metadata COMMENT = 'Creative asset metadata with image analysis and performance tags';
ALTER TABLE media_channel_engagement COMMENT = 'Channel-specific audience engagement metrics and reach data';
ALTER TABLE campaign_performance COMMENT = 'Core performance metrics linking campaigns, segments, and creatives';
ALTER TABLE attribution_events COMMENT = 'Event-level attribution tracking for cross-channel analysis';
ALTER TABLE consent_privacy COMMENT = 'Privacy compliance and consent management for audience data';

SHOW TABLES;
SELECT 'Database schema created successfully!' as status;
