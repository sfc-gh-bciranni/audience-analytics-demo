-- ========================================================================
-- RELOAD SCRIPT FOR FAILED TABLES
-- Run this script to reload the tables that failed during initial setup
-- ========================================================================

USE ROLE AUDIENCE_ANALYTICS_DEMO;
USE DATABASE AUDIENCE_ANALYTICS;
USE SCHEMA DEMO_SCHEMA;

-- Drop and recreate tables that failed to load properly
DROP TABLE IF EXISTS attribution_events;
DROP TABLE IF EXISTS campaign_performance;  
DROP TABLE IF EXISTS consent_privacy;

-- Recreation with corrected schemas (no foreign key constraints)
CREATE OR REPLACE TABLE campaign_performance (
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
    performance_date DATE DEFAULT (CURRENT_DATE)
);

CREATE OR REPLACE TABLE attribution_events (
    attribution_id VARCHAR(10) PRIMARY KEY,
    campaign_id VARCHAR(10) NOT NULL,
    audience_id VARCHAR(10) NOT NULL,
    media_channel VARCHAR(20) NOT NULL,
    timestamp DATETIME NOT NULL,
    touchpoint_type VARCHAR(20) NOT NULL,
    attribution_percent DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    benchmark DECIMAL(3,2) NOT NULL DEFAULT 0.00
);

CREATE OR REPLACE TABLE consent_privacy (
    consent_id VARCHAR(10) PRIMARY KEY,
    audience_id VARCHAR(10) NOT NULL UNIQUE,
    consent_status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    PII_flag BOOLEAN DEFAULT FALSE,
    privacy_signal_timestamp DATETIME NOT NULL,
    last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Reload data from GitHub repository stage with proper data type conversions
COPY INTO campaign_performance (performance_id, campaign_id, segment_id, creative_id, media_channel, impressions, clicks, conversions, cost, ROI, CTR)
FROM (
    SELECT $1, $2, $3, $4, $5, $6::INT, $7::INT, $8::INT, $9::DECIMAL(10,2), $10::DECIMAL(8,2), $11::DECIMAL(6,4)
    FROM @INTERNAL_DATA_STAGE/data/campaign_performance.csv
)
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

COPY INTO attribution_events (attribution_id, campaign_id, audience_id, media_channel, timestamp, touchpoint_type, attribution_percent, benchmark)
FROM (
    SELECT $1, $2, $3, $4, $5::DATETIME, $6, $7::DECIMAL(3,2), $8::DECIMAL(3,2)
    FROM @INTERNAL_DATA_STAGE/data/attribution_events.csv
)
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

COPY INTO consent_privacy (consent_id, audience_id, consent_status, PII_flag, privacy_signal_timestamp, last_updated)
FROM (
    SELECT $1, $2, $3, 
           CASE WHEN $4 = 'True' THEN TRUE WHEN $4 = 'False' THEN FALSE ELSE NULL END,
           $5::DATETIME, $6::DATETIME
    FROM @INTERNAL_DATA_STAGE/data/consent_privacy.csv
)
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Verify successful loads
SELECT 'CAMPAIGN_PERFORMANCE' as table_name, COUNT(*) as row_count FROM campaign_performance
UNION ALL
SELECT 'ATTRIBUTION_EVENTS', COUNT(*) FROM attribution_events  
UNION ALL
SELECT 'CONSENT_PRIVACY', COUNT(*) FROM consent_privacy;

-- Expected results:
-- CAMPAIGN_PERFORMANCE: ~5,000 records
-- ATTRIBUTION_EVENTS: ~8,000 records  
-- CONSENT_PRIVACY: ~1,200 records
