-- ========================================================================
-- DEBUG DATA LOADING ISSUES
-- This script will help identify specific problems with data loads
-- ========================================================================

USE ROLE AUDIENCE_ANALYTICS_DEMO;
USE DATABASE AUDIENCE_ANALYTICS;
USE SCHEMA DEMO_SCHEMA;

-- Check what files are available in the stage
SELECT * FROM DIRECTORY(@INTERNAL_DATA_STAGE);

-- Check the stage files 
LS @INTERNAL_DATA_STAGE/data/;

-- Try loading each problematic table with detailed error reporting

-- 1. Test campaign_performance with sample data
SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
FROM @INTERNAL_DATA_STAGE/data/campaign_performance.csv 
(FILE_FORMAT => CSV_FORMAT)
LIMIT 5;

-- 2. Test attribution_events with sample data  
SELECT $1, $2, $3, $4, $5, $6, $7, $8
FROM @INTERNAL_DATA_STAGE/data/attribution_events.csv
(FILE_FORMAT => CSV_FORMAT) 
LIMIT 5;

-- 3. Test consent_privacy with sample data
SELECT $1, $2, $3, $4, $5, $6  
FROM @INTERNAL_DATA_STAGE/data/consent_privacy.csv
(FILE_FORMAT => CSV_FORMAT)
LIMIT 5;

-- Try a simple COPY with validation mode first
COPY INTO campaign_performance (performance_id, campaign_id, segment_id, creative_id, media_channel, impressions, clicks, conversions, cost, ROI, CTR)
FROM @INTERNAL_DATA_STAGE/data/campaign_performance.csv
FILE_FORMAT = CSV_FORMAT
VALIDATION_MODE = 'RETURN_ERRORS';

COPY INTO attribution_events
FROM @INTERNAL_DATA_STAGE/data/attribution_events.csv  
FILE_FORMAT = CSV_FORMAT
VALIDATION_MODE = 'RETURN_ERRORS';

COPY INTO consent_privacy
FROM @INTERNAL_DATA_STAGE/data/consent_privacy.csv
FILE_FORMAT = CSV_FORMAT  
VALIDATION_MODE = 'RETURN_ERRORS';
