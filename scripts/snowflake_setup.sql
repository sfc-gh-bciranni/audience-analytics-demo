-- ========================================================================
-- Media Agency Audience Analytics - Complete Snowflake Setup Script
-- This script creates the database, schema, tables, and loads all data
-- Repository: https://github.com/sfc-gh-bciranni/audience-analytics-demo.git
-- ========================================================================

-- Switch to accountadmin role to create warehouse
USE ROLE accountadmin;

-- Enable Snowflake Intelligence by creating the Config DB & Schema
-- CREATE DATABASE IF NOT EXISTS snowflake_intelligence;
-- CREATE SCHEMA IF NOT EXISTS snowflake_intelligence.agents;

-- Allow anyone to see the agents in this schema
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;

create or replace role AUDIENCE_ANALYTICS_DEMO;

SET current_user_name = CURRENT_USER();

-- Step 2: Use the variable to grant the role
GRANT ROLE AUDIENCE_ANALYTICS_DEMO TO USER IDENTIFIER($current_user_name);
GRANT CREATE DATABASE ON ACCOUNT TO ROLE AUDIENCE_ANALYTICS_DEMO;

-- Create a dedicated warehouse for the demo with auto-suspend/resume
CREATE OR REPLACE WAREHOUSE AUDIENCE_ANALYTICS_WH 
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

-- Grant usage on warehouse to admin role
GRANT USAGE ON WAREHOUSE AUDIENCE_ANALYTICS_WH TO ROLE AUDIENCE_ANALYTICS_DEMO;

-- Alter current user's default role and warehouse to the ones used here
ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_ROLE = AUDIENCE_ANALYTICS_DEMO;
ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_WAREHOUSE = AUDIENCE_ANALYTICS_WH;

-- Switch to AUDIENCE_ANALYTICS_DEMO role to create demo objects
use role AUDIENCE_ANALYTICS_DEMO;

-- Create database and schema
CREATE OR REPLACE DATABASE AUDIENCE_ANALYTICS;
USE DATABASE AUDIENCE_ANALYTICS;

CREATE SCHEMA IF NOT EXISTS DEMO_SCHEMA;
USE SCHEMA DEMO_SCHEMA;

-- Create file format for CSV files
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    ESCAPE = 'NONE'
    ESCAPE_UNENCLOSED_FIELD = '\134'
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    NULL_IF = ('NULL', 'null', '', 'N/A', 'n/a');

use role accountadmin;
-- Create API Integration for GitHub (public repository access)
CREATE OR REPLACE API INTEGRATION git_api_integration_audience
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-bciranni/')
    ENABLED = TRUE;

GRANT USAGE ON INTEGRATION GIT_API_INTEGRATION_AUDIENCE TO ROLE AUDIENCE_ANALYTICS_DEMO;

use role AUDIENCE_ANALYTICS_DEMO;
-- Create Git repository integration for the public demo repository
CREATE OR REPLACE GIT REPOSITORY AUDIENCE_ANALYTICS_REPO
    API_INTEGRATION = git_api_integration_audience
    ORIGIN = 'https://github.com/sfc-gh-bciranni/audience-analytics-demo.git';

-- Create internal stage for copied data files
CREATE OR REPLACE STAGE INTERNAL_DATA_STAGE
    FILE_FORMAT = CSV_FORMAT
    COMMENT = 'Internal stage for copied audience analytics data files'
    DIRECTORY = ( ENABLE = TRUE)
    ENCRYPTION = (   TYPE = 'SNOWFLAKE_SSE');

ALTER GIT REPOSITORY AUDIENCE_ANALYTICS_REPO FETCH;

-- ========================================================================
-- COPY DATA FROM GIT TO INTERNAL STAGE
-- ========================================================================

-- Copy all CSV files from Git repository data folder to internal stage
COPY FILES
INTO @INTERNAL_DATA_STAGE/data/
FROM @AUDIENCE_ANALYTICS_REPO/branches/main/data/;

-- Verify files were copied
LS @INTERNAL_DATA_STAGE;

ALTER STAGE INTERNAL_DATA_STAGE refresh;

-- ========================================================================
-- AUDIENCE ANALYTICS TABLES
-- ========================================================================

-- Audience Demographics (Primary table)
CREATE OR REPLACE TABLE audience_demographics (
    audience_id VARCHAR(10) PRIMARY KEY,
    age_group VARCHAR(10) NOT NULL,
    gender VARCHAR(20) NOT NULL,
    state VARCHAR(2) NOT NULL,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(10) NOT NULL DEFAULT 'USA',
    household_income VARCHAR(15) NOT NULL,
    education_level VARCHAR(20) NOT NULL,
    ethnicity VARCHAR(30) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audience Segments (Many-to-Many with audiences)
CREATE OR REPLACE TABLE audience_segments (
    segment_id VARCHAR(10) PRIMARY KEY,
    audience_id VARCHAR(10) NOT NULL,
    segment_name VARCHAR(100) NOT NULL,
    primary_interest VARCHAR(50) NOT NULL,
    secondary_interest VARCHAR(50) NOT NULL,
    lookalike_segment_flag BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (audience_id) REFERENCES audience_demographics(audience_id)
);

-- Creative Metadata (Linked to campaigns)
CREATE OR REPLACE TABLE creative_metadata (
    creative_id VARCHAR(10) PRIMARY KEY,
    image_url VARCHAR(200) NOT NULL,
    creative_format VARCHAR(20) NOT NULL,
    content_type VARCHAR(30) NOT NULL,
    image_tags TEXT NOT NULL,
    sentiment_score DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    audit_status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    created_date DATE NOT NULL,
    campaign_id VARCHAR(10) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Media Channel Engagement (Audience channel behavior)
CREATE OR REPLACE TABLE media_channel_engagement (
    engagement_id VARCHAR(10) PRIMARY KEY,
    audience_id VARCHAR(10) NOT NULL,
    channel_type VARCHAR(20) NOT NULL,
    impressions INT NOT NULL DEFAULT 0,
    reach INT NOT NULL DEFAULT 0,
    frequency DECIMAL(6,2) NOT NULL DEFAULT 1.00,
    engagement_rate DECIMAL(6,4) NOT NULL DEFAULT 0.0000,
    measurement_date DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (audience_id) REFERENCES audience_demographics(audience_id)
);

-- Campaign Performance (Central analytics table)
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
    performance_date DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (segment_id) REFERENCES audience_segments(segment_id),
    FOREIGN KEY (creative_id) REFERENCES creative_metadata(creative_id)
);

-- Attribution Events (Event-level tracking)
CREATE OR REPLACE TABLE attribution_events (
    attribution_id VARCHAR(10) PRIMARY KEY,
    campaign_id VARCHAR(10) NOT NULL,
    audience_id VARCHAR(10) NOT NULL,
    media_channel VARCHAR(20) NOT NULL,
    timestamp DATETIME NOT NULL,
    touchpoint_type VARCHAR(20) NOT NULL,
    attribution_percent DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    benchmark DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (audience_id) REFERENCES audience_demographics(audience_id)
);

-- Consent Privacy (GDPR/CCPA compliance)
CREATE OR REPLACE TABLE consent_privacy (
    consent_id VARCHAR(10) PRIMARY KEY,
    audience_id VARCHAR(10) NOT NULL UNIQUE,
    consent_status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    PII_flag BOOLEAN DEFAULT FALSE,
    privacy_signal_timestamp DATETIME NOT NULL,
    last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (audience_id) REFERENCES audience_demographics(audience_id)
);

-- ========================================================================
-- LOAD DATA FROM INTERNAL STAGE
-- ========================================================================

-- Load Audience Demographics
COPY INTO audience_demographics
FROM @INTERNAL_DATA_STAGE/data/audience_demographics.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Load Audience Segments
COPY INTO audience_segments
FROM @INTERNAL_DATA_STAGE/data/audience_segments.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Load Creative Metadata
COPY INTO creative_metadata
FROM @INTERNAL_DATA_STAGE/data/creative_metadata.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Load Media Channel Engagement
COPY INTO media_channel_engagement
FROM @INTERNAL_DATA_STAGE/data/media_channel_engagement.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Load Campaign Performance
COPY INTO campaign_performance
FROM @INTERNAL_DATA_STAGE/data/campaign_performance.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Load Attribution Events
COPY INTO attribution_events
FROM @INTERNAL_DATA_STAGE/data/attribution_events.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- Load Consent Privacy
COPY INTO consent_privacy
FROM @INTERNAL_DATA_STAGE/data/consent_privacy.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

-- ========================================================================
-- VERIFICATION
-- ========================================================================

-- Verify data loads
SELECT 'AUDIENCE ANALYTICS TABLES' as category, '' as table_name, NULL as row_count
UNION ALL
SELECT '', 'audience_demographics', COUNT(*) FROM audience_demographics
UNION ALL
SELECT '', 'audience_segments', COUNT(*) FROM audience_segments
UNION ALL
SELECT '', 'creative_metadata', COUNT(*) FROM creative_metadata
UNION ALL
SELECT '', 'media_channel_engagement', COUNT(*) FROM media_channel_engagement
UNION ALL
SELECT '', 'campaign_performance', COUNT(*) FROM campaign_performance
UNION ALL
SELECT '', 'attribution_events', COUNT(*) FROM attribution_events
UNION ALL
SELECT '', 'consent_privacy', COUNT(*) FROM consent_privacy;

-- Show all tables
SHOW TABLES IN SCHEMA DEMO_SCHEMA;

-- ========================================================================
-- SEMANTIC VIEWS FOR CORTEX ANALYST
-- ========================================================================
USE ROLE AUDIENCE_ANALYTICS_DEMO;
USE DATABASE AUDIENCE_ANALYTICS;
USE SCHEMA DEMO_SCHEMA;

-- AUDIENCE DEMOGRAPHICS & SEGMENTS SEMANTIC VIEW
CREATE OR REPLACE SEMANTIC VIEW AUDIENCE_ANALYTICS.DEMO_SCHEMA.AUDIENCE_SEMANTIC_VIEW
    TABLES (
        demographics AS AUDIENCE_DEMOGRAPHICS PRIMARY KEY (audience_id) WITH SYNONYMS = ('audiences','demographics','users') COMMENT = 'Core audience demographic data for targeting and segmentation',
        segments AS AUDIENCE_SEGMENTS PRIMARY KEY (segment_id) WITH SYNONYMS = ('segments','groups','cohorts') COMMENT = 'Multi-dimensional audience segments with interest-based classifications',
        consent AS CONSENT_PRIVACY PRIMARY KEY (consent_id) WITH SYNONYMS = ('privacy','consent','gdpr') COMMENT = 'Privacy compliance and consent status for audiences'
    )
    RELATIONSHIPS (
        segments(audience_id) REFERENCES demographics(audience_id),
        consent(audience_id) REFERENCES demographics(audience_id)
    )
    DIMENSIONS (
        demographics.audience_id AS demographics.audience_id WITH SYNONYMS = ('user_id','audience_identifier') COMMENT = 'Unique audience identifier',
        demographics.age_group AS demographics.age_group WITH SYNONYMS = ('age','demographic_age') COMMENT = 'Age group classification',
        demographics.gender AS demographics.gender WITH SYNONYMS = ('sex','demographic_gender') COMMENT = 'Gender classification',
        demographics.state AS demographics.state WITH SYNONYMS = ('location','geography') COMMENT = 'Geographic state',
        demographics.city AS demographics.city WITH SYNONYMS = ('location','metro') COMMENT = 'Geographic city',
        demographics.household_income AS demographics.household_income WITH SYNONYMS = ('income_level','economic_segment') COMMENT = 'Household income bracket',
        demographics.education_level AS demographics.education_level WITH SYNONYMS = ('education_level','academic_level') COMMENT = 'Education level',
        demographics.ethnicity AS demographics.ethnicity WITH SYNONYMS = ('race','demographic_ethnicity') COMMENT = 'Ethnic background',
        segments.segment_name AS segments.segment_name WITH SYNONYMS = ('segment','group_name') COMMENT = 'Name of audience segment',
        segments.primary_interest AS segments.primary_interest WITH SYNONYMS = ('main_interest','category') COMMENT = 'Primary interest category',
        segments.secondary_interest AS segments.secondary_interest WITH SYNONYMS = ('sub_interest','subcategory') COMMENT = 'Secondary interest category',
        segments.lookalike_segment_flag AS segments.lookalike_segment_flag WITH SYNONYMS = ('lookalike','modeled_segment') COMMENT = 'Indicates if segment is lookalike modeled',
        consent.consent_status AS consent.consent_status WITH SYNONYMS = ('privacy_status','opt_status') COMMENT = 'Privacy consent status',
        consent.PII_flag AS consent.PII_flag WITH SYNONYMS = ('personal_data','sensitive_data') COMMENT = 'Contains personally identifiable information'
    )
    COMMENT = 'Semantic view for audience demographics, segmentation, and privacy analysis';

-- CREATIVE PERFORMANCE SEMANTIC VIEW
CREATE OR REPLACE SEMANTIC VIEW AUDIENCE_ANALYTICS.DEMO_SCHEMA.CREATIVE_SEMANTIC_VIEW
    TABLES (
        creatives AS CREATIVE_METADATA PRIMARY KEY (creative_id) WITH SYNONYMS = ('creatives','assets','content') COMMENT = 'Creative asset metadata with image analysis and performance tags',
        performance AS CAMPAIGN_PERFORMANCE PRIMARY KEY (performance_id) WITH SYNONYMS = ('campaign_performance','performance_data') COMMENT = 'Core performance metrics linking campaigns, segments, and creatives',
        segments AS AUDIENCE_SEGMENTS PRIMARY KEY (segment_id) WITH SYNONYMS = ('audience_segments','segments') COMMENT = 'Audience segments for performance analysis'
    )
    RELATIONSHIPS (
        performance(creative_id) REFERENCES creatives(creative_id),
        performance(segment_id) REFERENCES segments(segment_id)
    )
    DIMENSIONS (
        creatives.creative_id AS creatives.creative_id WITH SYNONYMS = ('asset_id','creative_identifier') COMMENT = 'Unique creative identifier',
        creatives.image_url AS creatives.image_url WITH SYNONYMS = ('asset_url','creative_url') COMMENT = 'URL to creative asset',
        creatives.creative_format AS creatives.creative_format WITH SYNONYMS = ('ad_format','creative_type') COMMENT = 'Format of creative asset',
        creatives.content_type AS creatives.content_type WITH SYNONYMS = ('creative_category','asset_type') COMMENT = 'Type of creative content',
        creatives.image_tags AS creatives.image_tags WITH SYNONYMS = ('creative_tags','keywords') COMMENT = 'Tags describing creative content',
        creatives.sentiment_score AS creatives.sentiment_score WITH SYNONYMS = ('emotional_score','sentiment_analysis') COMMENT = 'Sentiment analysis score for creative',
        creatives.audit_status AS creatives.audit_status WITH SYNONYMS = ('approval_status','creative_status') COMMENT = 'Audit and approval status',
        creatives.campaign_id AS creatives.campaign_id WITH SYNONYMS = ('campaign_identifier') COMMENT = 'Campaign identifier',
        performance.media_channel AS performance.media_channel WITH SYNONYMS = ('media_channel','advertising_channel') COMMENT = 'Media channel used',
        performance.performance_date AS performance.performance_date WITH SYNONYMS = ('campaign_date','performance_date') COMMENT = 'Date of performance measurement',
        segments.primary_interest AS segments.primary_interest WITH SYNONYMS = ('target_interest','audience_category') COMMENT = 'Primary interest of target audience'
    )
    COMMENT = 'Semantic view for creative performance optimization and asset analysis';

-- ATTRIBUTION & ENGAGEMENT SEMANTIC VIEW
CREATE OR REPLACE SEMANTIC VIEW AUDIENCE_ANALYTICS.DEMO_SCHEMA.ATTRIBUTION_SEMANTIC_VIEW
    TABLES (
        attribution AS ATTRIBUTION_EVENTS PRIMARY KEY (attribution_id) WITH SYNONYMS = ('attribution','touchpoints','journey') COMMENT = 'Event-level attribution tracking for cross-channel analysis',
        engagement AS MEDIA_CHANNEL_ENGAGEMENT PRIMARY KEY (engagement_id) WITH SYNONYMS = ('channel_engagement','media_engagement') COMMENT = 'Channel-specific audience engagement metrics and reach data',
        demographics AS AUDIENCE_DEMOGRAPHICS PRIMARY KEY (audience_id) WITH SYNONYMS = ('audiences','users') COMMENT = 'Audience demographic information for attribution analysis'
    )
    RELATIONSHIPS (
        attribution(audience_id) REFERENCES demographics(audience_id),
        engagement(audience_id) REFERENCES demographics(audience_id)
    )
    DIMENSIONS (
        attribution.campaign_id AS attribution.campaign_id WITH SYNONYMS = ('campaign_identifier') COMMENT = 'Campaign identifier for attribution',
        attribution.media_channel AS attribution.media_channel WITH SYNONYMS = ('channel','media_type') COMMENT = 'Media channel for attribution',
        attribution.timestamp AS attribution.timestamp WITH SYNONYMS = ('event_timestamp','touchpoint_time') COMMENT = 'Timestamp of attribution event',
        attribution.touchpoint_type AS attribution.touchpoint_type WITH SYNONYMS = ('interaction_type','event_type') COMMENT = 'Type of customer touchpoint',
        engagement.channel_type AS engagement.channel_type WITH SYNONYMS = ('media_channel','channel') COMMENT = 'Media channel for engagement',
        engagement.measurement_date AS engagement.measurement_date WITH SYNONYMS = ('engagement_date','measurement_time') COMMENT = 'Date of engagement measurement',
        demographics.age_group AS demographics.age_group WITH SYNONYMS = ('age_segment','demographic_age') COMMENT = 'Age group of audience',
        demographics.state AS demographics.state WITH SYNONYMS = ('geography','location') COMMENT = 'Geographic location of audience'
    )
    COMMENT = 'Semantic view for attribution modeling and cross-channel engagement analysis';

-- ========================================================================
-- VERIFICATION OF SEMANTIC VIEWS
-- ========================================================================

-- Show all semantic views
SHOW SEMANTIC VIEWS;

-- Show dimensions for each semantic view
SHOW SEMANTIC DIMENSIONS;

-- Show metrics for each semantic view
SHOW SEMANTIC METRICS;

-- ========================================================================
-- CORTEX SEARCH SERVICES
-- ========================================================================
USE ROLE AUDIENCE_ANALYTICS_DEMO;

-- Note: For Cortex Search, we would need unstructured documents
-- This is a placeholder for when documentation is added to the repository

/*
-- Create search service for audience research documents
CREATE OR REPLACE CORTEX SEARCH SERVICE Search_audience_docs
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = AUDIENCE_ANALYTICS_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') as title,
            content
        FROM parsed_content
        WHERE relative_path ilike '%/audience/%'
    );
*/

-- ========================================================================
-- EXTERNAL ACCESS INTEGRATION FOR WEB SCRAPING
-- ========================================================================
use role accountadmin;

GRANT ALL PRIVILEGES ON DATABASE AUDIENCE_ANALYTICS TO ROLE ACCOUNTADMIN;
GRANT ALL PRIVILEGES ON SCHEMA AUDIENCE_ANALYTICS.DEMO_SCHEMA TO ROLE ACCOUNTADMIN;

USE SCHEMA AUDIENCE_ANALYTICS.DEMO_SCHEMA;

-- NETWORK rule is part of db schema
CREATE OR REPLACE NETWORK RULE AUDIENCE_ANALYTICS_WebAccessRule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('0.0.0.0:80', '0.0.0.0:443');

GRANT USAGE ON NETWORK RULE AUDIENCE_ANALYTICS_WebAccessRule TO ROLE accountadmin;

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION AUDIENCE_ANALYTICS_ExternalAccess_Integration
ALLOWED_NETWORK_RULES = (AUDIENCE_ANALYTICS_WebAccessRule)
ENABLED = true;

CREATE NOTIFICATION INTEGRATION ai_email_int
  TYPE=EMAIL
  ENABLED=TRUE;

GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE AUDIENCE_ANALYTICS_DEMO;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE AUDIENCE_ANALYTICS_DEMO;
GRANT CREATE AGENT ON SCHEMA snowflake_intelligence.agents TO ROLE AUDIENCE_ANALYTICS_DEMO;

GRANT USAGE ON INTEGRATION AUDIENCE_ANALYTICS_ExternalAccess_Integration TO ROLE AUDIENCE_ANALYTICS_DEMO;
GRANT USAGE ON INTEGRATION AI_EMAIL_INT TO ROLE AUDIENCE_ANALYTICS_DEMO;

use role AUDIENCE_ANALYTICS_DEMO;

-- ========================================================================
-- STORED PROCEDURES AND FUNCTIONS
-- ========================================================================

-- Web scraping function for external content analysis
CREATE OR REPLACE FUNCTION Web_scrape(weburl STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.11
HANDLER = 'get_page'
EXTERNAL_ACCESS_INTEGRATIONS = (AUDIENCE_ANALYTICS_ExternalAccess_Integration)
PACKAGES = ('requests', 'beautifulsoup4')
AS
$$
import _snowflake
import requests
from bs4 import BeautifulSoup

def get_page(weburl):
  url = f"{weburl}"
  response = requests.get(url)
  soup = BeautifulSoup(response.text)
  return soup.get_text()
$$;

-- Email notification function
CREATE OR REPLACE PROCEDURE send_mail(recipient TEXT, subject TEXT, text TEXT)
RETURNS TEXT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'send_mail'
AS
$$
def send_mail(session, recipient, subject, text):
    session.call(
        'SYSTEM$SEND_EMAIL',
        'ai_email_int',
        recipient,
        subject,
        text,
        'text/html'
    )
    return f'Email was sent to {recipient} with subject: "{subject}".'
$$;

-- ========================================================================
-- SNOWFLAKE INTELLIGENCE AGENT
-- ========================================================================

CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.Audience_Analytics_Agent
WITH PROFILE='{ "display_name": "Media Agency Audience Analytics Agent" }'
    COMMENT=$$ This is an agent that can answer questions about audience analytics, creative performance, attribution modeling, and privacy compliance. $$
FROM SPECIFICATION $$
{
  "models": {
    "orchestration": ""
  },
  "instructions": {
    "response": "You are a media analytics expert who has access to comprehensive audience, creative, and attribution data. Help users understand audience behavior, optimize creative performance, analyze attribution paths, and ensure privacy compliance. Provide visualizations when possible. Use line charts for trends and bar charts for categories.",
    "orchestration": "Use semantic views to analyze audience demographics, creative performance, and attribution data. Always consider privacy consent status when analyzing audience data. Focus on actionable insights for media planning and optimization.",
    "sample_questions": [
      {
        "question": "What are the top performing creative formats by audience segment?"
      },
      {
        "question": "Show me attribution paths for high-value conversions"
      },
      {
        "question": "Which audience segments have the highest engagement rates across channels?"
      }
    ]
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Audience Analytics",
        "description": "Allows users to query audience demographics, segments, and privacy consent data for targeting and segmentation analysis."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Creative Performance",
        "description": "Allows users to query creative metadata, performance metrics, and campaign results for creative optimization analysis."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Attribution & Engagement",
        "description": "Allows users to query attribution events, touchpoint analysis, and channel engagement data for customer journey analysis."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "Web_scraper",
        "description": "This tool should be used if the user wants to analyze contents of a given web page for competitive intelligence or market research.",
        "input_schema": {
          "type": "object",
          "properties": {
            "weburl": {
              "description": "Web URL (http:// or https://) to scrape and analyze content from",
              "type": "string"
            }
          },
          "required": [
            "weburl"
          ]
        }
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "Send_Emails",
        "description": "This tool is used to send email reports and insights to stakeholders. Always use HTML formatted content.",
        "input_schema": {
          "type": "object",
          "properties": {
            "recipient": {
              "description": "Email recipient address",
              "type": "string"
            },
            "subject": {
              "description": "Email subject line",
              "type": "string"
            },
            "text": {
              "description": "HTML formatted email content",
              "type": "string"
            }
          },
          "required": [
            "text",
            "recipient",
            "subject"
          ]
        }
      }
    }
  ],
  "tool_resources": {
    "Query Audience Analytics": {
      "semantic_view": "AUDIENCE_ANALYTICS.DEMO_SCHEMA.AUDIENCE_SEMANTIC_VIEW"
    },
    "Query Creative Performance": {
      "semantic_view": "AUDIENCE_ANALYTICS.DEMO_SCHEMA.CREATIVE_SEMANTIC_VIEW"
    },
    "Query Attribution & Engagement": {
      "semantic_view": "AUDIENCE_ANALYTICS.DEMO_SCHEMA.ATTRIBUTION_SEMANTIC_VIEW"
    },
    "Web_scraper": {
      "execution_environment": {
        "query_timeout": 0,
        "type": "warehouse",
        "warehouse": "AUDIENCE_ANALYTICS_WH"
      },
      "identifier": "AUDIENCE_ANALYTICS.DEMO_SCHEMA.WEB_SCRAPE",
      "name": "WEB_SCRAPE(VARCHAR)",
      "type": "function"
    },
    "Send_Emails": {
      "execution_environment": {
        "query_timeout": 0,
        "type": "warehouse",
        "warehouse": "AUDIENCE_ANALYTICS_WH"
      },
      "identifier": "AUDIENCE_ANALYTICS.DEMO_SCHEMA.SEND_MAIL",
      "name": "SEND_MAIL(VARCHAR, VARCHAR, VARCHAR)",
      "type": "procedure"
    }
  }
}
$$;

-- ========================================================================
-- FINAL VERIFICATION
-- ========================================================================

-- Show Git repositories
SHOW GIT REPOSITORIES;

-- Show final table count
SELECT 'Final Table Counts' as summary;

SELECT 'audience_demographics' as table_name, COUNT(*) as records FROM audience_demographics
UNION ALL
SELECT 'audience_segments', COUNT(*) FROM audience_segments  
UNION ALL
SELECT 'creative_metadata', COUNT(*) FROM creative_metadata
UNION ALL
SELECT 'media_channel_engagement', COUNT(*) FROM media_channel_engagement
UNION ALL  
SELECT 'campaign_performance', COUNT(*) FROM campaign_performance
UNION ALL
SELECT 'attribution_events', COUNT(*) FROM attribution_events
UNION ALL
SELECT 'consent_privacy', COUNT(*) FROM consent_privacy;

-- Show semantic views
SHOW SEMANTIC VIEWS;

-- Show agents
SHOW AGENTS;

SELECT 'Setup Complete! 🎉' as status, 
       'Access your Audience Analytics Agent in Snowflake Intelligence' as next_step;
