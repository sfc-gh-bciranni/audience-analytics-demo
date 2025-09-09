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
    tables (
        AUDIENCE_DEMOGRAPHICS,
        AUDIENCE_SEGMENTS,
        CONSENT_PRIVACY
    )
    relationships (
        AUDIENCE_SEGMENTS(audience_id) references AUDIENCE_DEMOGRAPHICS(audience_id),
        CONSENT_PRIVACY(audience_id) references AUDIENCE_DEMOGRAPHICS(audience_id)
    )
    dimensions (
        AUDIENCE_DEMOGRAPHICS.audience_id with synonyms=('user_id','audience_identifier') comment='Unique audience identifier',
        AUDIENCE_DEMOGRAPHICS.age_group with synonyms=('age','demographic_age') comment='Age group classification',
        AUDIENCE_DEMOGRAPHICS.gender with synonyms=('sex','demographic_gender') comment='Gender classification',
        AUDIENCE_DEMOGRAPHICS.state with synonyms=('location','geography') comment='Geographic state',
        AUDIENCE_DEMOGRAPHICS.city with synonyms=('location','metro') comment='Geographic city',
        AUDIENCE_DEMOGRAPHICS.household_income with synonyms=('income_level','economic_segment') comment='Household income bracket',
        AUDIENCE_DEMOGRAPHICS.education_level with synonyms=('education_level','academic_level') comment='Education level',
        AUDIENCE_DEMOGRAPHICS.ethnicity with synonyms=('race','demographic_ethnicity') comment='Ethnic background',
        AUDIENCE_SEGMENTS.segment_name with synonyms=('segment','group_name') comment='Name of audience segment',
        AUDIENCE_SEGMENTS.primary_interest with synonyms=('main_interest','category') comment='Primary interest category',
        AUDIENCE_SEGMENTS.secondary_interest with synonyms=('sub_interest','subcategory') comment='Secondary interest category',
        AUDIENCE_SEGMENTS.lookalike_segment_flag with synonyms=('lookalike','modeled_segment') comment='Indicates if segment is lookalike modeled',
        CONSENT_PRIVACY.consent_status with synonyms=('privacy_status','opt_status') comment='Privacy consent status',
        CONSENT_PRIVACY.PII_flag with synonyms=('personal_data','sensitive_data') comment='Contains personally identifiable information'
    )
    comment='Semantic view for audience demographics, segmentation, and privacy analysis';

-- CREATIVE PERFORMANCE SEMANTIC VIEW
CREATE OR REPLACE SEMANTIC VIEW AUDIENCE_ANALYTICS.DEMO_SCHEMA.CREATIVE_SEMANTIC_VIEW
    tables (
        CREATIVE_METADATA,
        CAMPAIGN_PERFORMANCE,
        AUDIENCE_SEGMENTS
    )
    relationships (
        CAMPAIGN_PERFORMANCE(creative_id) references CREATIVE_METADATA(creative_id),
        CAMPAIGN_PERFORMANCE(segment_id) references AUDIENCE_SEGMENTS(segment_id)
    )
    dimensions (
        CREATIVE_METADATA.creative_id with synonyms=('asset_id','creative_identifier') comment='Unique creative identifier',
        CREATIVE_METADATA.image_url with synonyms=('asset_url','creative_url') comment='URL to creative asset',
        CREATIVE_METADATA.creative_format with synonyms=('ad_format','creative_type') comment='Format of creative asset',
        CREATIVE_METADATA.content_type with synonyms=('creative_category','asset_type') comment='Type of creative content',
        CREATIVE_METADATA.image_tags with synonyms=('creative_tags','keywords') comment='Tags describing creative content',
        CREATIVE_METADATA.sentiment_score with synonyms=('emotional_score','sentiment_analysis') comment='Sentiment analysis score for creative',
        CREATIVE_METADATA.audit_status with synonyms=('approval_status','creative_status') comment='Audit and approval status',
        CREATIVE_METADATA.campaign_id with synonyms=('campaign_identifier') comment='Campaign identifier',
        CAMPAIGN_PERFORMANCE.media_channel with synonyms=('media_channel','advertising_channel') comment='Media channel used',
        CAMPAIGN_PERFORMANCE.performance_date with synonyms=('campaign_date','performance_date') comment='Date of performance measurement',
        AUDIENCE_SEGMENTS.primary_interest with synonyms=('target_interest','audience_category') comment='Primary interest of target audience'
    )
    comment='Semantic view for creative performance optimization and asset analysis';

-- ATTRIBUTION & ENGAGEMENT SEMANTIC VIEW
CREATE OR REPLACE SEMANTIC VIEW AUDIENCE_ANALYTICS.DEMO_SCHEMA.ATTRIBUTION_SEMANTIC_VIEW
    tables (
        ATTRIBUTION_EVENTS,
        MEDIA_CHANNEL_ENGAGEMENT,
        AUDIENCE_DEMOGRAPHICS
    )
    relationships (
        ATTRIBUTION_EVENTS(audience_id) references AUDIENCE_DEMOGRAPHICS(audience_id),
        MEDIA_CHANNEL_ENGAGEMENT(audience_id) references AUDIENCE_DEMOGRAPHICS(audience_id)
    )
    dimensions (
        ATTRIBUTION_EVENTS.campaign_id with synonyms=('campaign_identifier') comment='Campaign identifier for attribution',
        ATTRIBUTION_EVENTS.media_channel with synonyms=('channel','media_type') comment='Media channel for attribution',
        ATTRIBUTION_EVENTS.timestamp with synonyms=('event_timestamp','touchpoint_time') comment='Timestamp of attribution event',
        ATTRIBUTION_EVENTS.touchpoint_type with synonyms=('interaction_type','event_type') comment='Type of customer touchpoint',
        MEDIA_CHANNEL_ENGAGEMENT.channel_type with synonyms=('media_channel','channel') comment='Media channel for engagement',
        MEDIA_CHANNEL_ENGAGEMENT.measurement_date with synonyms=('engagement_date','measurement_time') comment='Date of engagement measurement',
        AUDIENCE_DEMOGRAPHICS.age_group with synonyms=('age_segment','demographic_age') comment='Age group of audience',
        AUDIENCE_DEMOGRAPHICS.state with synonyms=('geography','location') comment='Geographic location of audience'
    )
    comment='Semantic view for attribution modeling and cross-channel engagement analysis';

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
