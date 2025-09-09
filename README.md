# Media Agency Audience Analytics Demo Dataset

A comprehensive, realistic dataset for demonstrating audience exploration and creative optimization capabilities in modern media agency workflows.

## 🎯 Overview

This dataset simulates a complete audience analytics ecosystem with **24,106 total records** across 7 interconnected tables, designed specifically for modern media agencies. The data supports advanced analytics for:

- **Creative Performance Optimization** - Link visual assets to campaign performance
- **Audience Intelligence** - Multi-dimensional segmentation and targeting  
- **Attribution Modeling** - Cross-channel customer journey analysis
- **Privacy Compliance** - GDPR/CCPA consent management

## 📊 Dataset Summary

| Table | Records | Description |
|-------|---------|-------------|
| **audience_demographics** | 1,200 | Core demographic profiles with geographic and socioeconomic data |
| **audience_segments** | 3,020 | Interest-based segments with lookalike modeling (2.5 segments per audience) |
| **creative_metadata** | 1,500 | Image/video assets with tags, sentiment analysis, and audit status |
| **media_channel_engagement** | 4,186 | Channel-specific engagement metrics across 9 media types |
| **campaign_performance** | 5,000 | Core performance data linking campaigns, segments, and creatives |
| **attribution_events** | 8,000 | Event-level touchpoint tracking for journey analysis |
| **consent_privacy** | 1,200 | Privacy compliance and consent status for all audiences |

**Total Investment Simulated:** $2.48M across 400 campaigns  
**Total Conversions:** 96,937 with realistic ROI distribution  
**Geographic Coverage:** 20 US states with authentic city distributions

## 🏗️ Database Schema

### Core Relationships
```
audience_demographics (1) ←→ (N) audience_segments
audience_segments (1) ←→ (N) campaign_performance  
creative_metadata (1) ←→ (N) campaign_performance
audience_demographics (1) ←→ (1) consent_privacy
audience_demographics (1) ←→ (N) media_channel_engagement
audience_demographics (1) ←→ (N) attribution_events
```

### Key Features
- **Foreign key integrity** maintained across all tables
- **Realistic data distributions** with proper statistical variation  
- **Creative-to-campaign linking** enables visual asset performance analysis
- **Multi-channel attribution** supports complex customer journey mapping
- **Privacy compliance** built-in for GDPR/CCPA requirements

## 🚀 Quick Start

### Option 1: Snowflake Intelligence Setup (Recommended)

**Complete setup with AI agent in one script:**

1. **GitHub Repository**
   - Repository: `https://github.com/sfc-gh-bciranni/audience-analytics-demo`
   - Data files organized in `/data` folder for clean structure
   - All files automatically loaded via git integration

2. **Run Snowflake Setup**
   ```sql
   -- Execute the complete setup script in Snowflake
   -- This creates database, loads data, and sets up AI agent
   SOURCE scripts/snowflake_setup.sql;
   ```

3. **Access Your AI Agent**
   - Go to Snowflake AI/ML → Snowflake Intelligence
   - Select "Media Agency Audience Analytics Agent"
   - Start querying with natural language!

### Option 2: Manual Database Setup

1. **Set Up Database**
```sql
-- Create schema and tables
SOURCE scripts/create_database_schema.sql;

-- Import CSV data (example for MySQL)
LOAD DATA INFILE 'audience_demographics.csv' 
INTO TABLE audience_demographics 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

-- Repeat for all 7 CSV files
```

2. **Verify Data Import**
```sql
-- Check record counts
SELECT 'audience_demographics' as table_name, COUNT(*) as records FROM audience_demographics
UNION ALL
SELECT 'audience_segments', COUNT(*) FROM audience_segments
UNION ALL  
SELECT 'creative_metadata', COUNT(*) FROM creative_metadata
-- ... continue for all tables
```

3. **Run Sample Analytics**
```sql
-- Load and execute demonstration queries
SOURCE scripts/sample_analytics_queries.sql;
```

## 🎨 Creative Integration Capabilities

### Visual Asset Metadata
- **1,500 creative assets** with realistic image URLs and metadata
- **Sentiment analysis** scores (-1.0 to 1.0) for emotional impact assessment
- **Content classification** (Product Shot, Lifestyle, Promotional, etc.)
- **Format diversity** (Banner, Video, Native, Rich Media, CTV, Social Post)
- **Audit workflows** with approval status tracking

### Creative Performance Analysis
```sql
-- Top performing creatives for Fashion & Beauty audience
SELECT cm.creative_id, cm.image_url, cm.content_type, 
       AVG(cp.CTR) as avg_ctr, AVG(cp.ROI) as avg_roi
FROM creative_metadata cm
JOIN campaign_performance cp ON cm.creative_id = cp.creative_id  
JOIN audience_segments aseg ON cp.segment_id = aseg.segment_id
WHERE aseg.primary_interest = 'Fashion & Beauty'
GROUP BY cm.creative_id, cm.image_url, cm.content_type
ORDER BY avg_roi DESC;
```

### Image Tag Filtering
```sql
-- Filter lifestyle creatives with performance metrics
SELECT cm.creative_id, cm.image_url, cm.image_tags,
       SUM(cp.conversions) as total_conversions
FROM creative_metadata cm
JOIN campaign_performance cp ON cm.creative_id = cp.creative_id
WHERE cm.image_tags LIKE '%lifestyle%'
GROUP BY cm.creative_id, cm.image_url, cm.image_tags
ORDER BY total_conversions DESC;
```

## 📈 Sample Analytics Use Cases

### 1. Audience Segment Performance
```sql
-- Compare ROI across audience interests
SELECT aseg.primary_interest,
       COUNT(DISTINCT aseg.audience_id) as audience_size,
       AVG(cp.ROI) as avg_roi,
       SUM(cp.conversions) as total_conversions
FROM audience_segments aseg
JOIN campaign_performance cp ON aseg.segment_id = cp.segment_id  
GROUP BY aseg.primary_interest
ORDER BY avg_roi DESC;
```

### 2. Cross-Channel Attribution
```sql
-- Customer journey analysis
SELECT ae.audience_id,
       COUNT(DISTINCT ae.media_channel) as channels_touched,
       STRING_AGG(ae.media_channel, ' → ') as journey_path
FROM attribution_events ae
GROUP BY ae.audience_id
HAVING channels_touched > 2
ORDER BY channels_touched DESC;
```

### 3. Creative Sentiment Impact
```sql
-- Sentiment vs performance correlation
SELECT CASE 
         WHEN cm.sentiment_score > 0.5 THEN 'Highly Positive'
         WHEN cm.sentiment_score > 0 THEN 'Positive'  
         ELSE 'Neutral/Negative'
       END as sentiment_category,
       AVG(cp.CTR) as avg_ctr,
       AVG(cp.ROI) as avg_roi
FROM creative_metadata cm
JOIN campaign_performance cp ON cm.creative_id = cp.creative_id
GROUP BY sentiment_category;
```

## 🔒 Privacy & Compliance

### GDPR/CCPA Support
- **Consent tracking** with timestamps and status management
- **PII flagging** for data processing compliance
- **Opt-out workflows** properly modeled
- **Data retention** policies can be implemented via timestamps

### Privacy Analytics
```sql
-- Consent status impact on engagement
SELECT cp.consent_status,
       COUNT(DISTINCT ad.audience_id) as audience_count,
       AVG(mce.engagement_rate) as avg_engagement
FROM consent_privacy cp
JOIN audience_demographics ad ON cp.audience_id = ad.audience_id  
JOIN media_channel_engagement mce ON ad.audience_id = mce.audience_id
GROUP BY cp.consent_status;
```

## 📝 Data Quality & Validation

### Realistic Distributions
- **Age groups:** Even distribution across 18-65+ demographics
- **Geography:** Weighted by US population with major metro focus
- **Income:** Realistic household income distribution  
- **Interests:** 24 primary + 16 secondary interest categories
- **Channels:** 9 media types with authentic engagement patterns

### Performance Metrics
- **CTR ranges:** 0.5% to 4% based on channel type
- **ROI distribution:** -10 to +49 with realistic business outcomes
- **Cost structures:** Channel-appropriate CPM and CPC rates
- **Conversion rates:** 1% to 5% funnel optimization

### Data Integrity
✅ All foreign key relationships verified  
✅ No orphaned records across tables  
✅ Realistic statistical distributions maintained  
✅ Cross-table consistency validated  

## 🛠️ Files Included

### Project Structure
```
audience-analytics-demo/
├── data/                           # CSV data files (24,106 records)
├── scripts/                        # SQL scripts and Python utilities  
├── docs/                          # Documentation and setup guides
├── README.md                      # This file
└── LICENSE                        # Apache 2.0 license
```

### Data Files (`/data` folder)
| File | Purpose | Records |
|------|---------|---------|
| `data/audience_demographics.csv` | Core demographic data | 1,200 |
| `data/audience_segments.csv` | Interest-based segments | 3,020 |
| `data/creative_metadata.csv` | Visual asset metadata | 1,500 |
| `data/media_channel_engagement.csv` | Channel engagement metrics | 4,186 |
| `data/campaign_performance.csv` | Core performance data | 5,000 |
| `data/attribution_events.csv` | Touchpoint tracking | 8,000 |
| `data/consent_privacy.csv` | Privacy compliance | 1,200 |

### Scripts (`/scripts` folder)
| File | Purpose | Type |
|------|---------|------|
| `scripts/snowflake_setup.sql` | Complete Snowflake + AI setup | SQL |
| `scripts/create_database_schema.sql` | Manual database setup | SQL |
| `scripts/sample_analytics_queries.sql` | 15 demonstration queries | SQL |
| `scripts/generate_audience_data.py` | Data generation script | Python |
| `scripts/data_summary_report.py` | Validation and analysis | Python |

### Documentation (`/docs` folder)
| File | Purpose |
|------|---------|
| `docs/github_setup_instructions.md` | GitHub repository setup guide |

## 🤖 Snowflake Intelligence Agent Capabilities

The AI agent can answer natural language questions like:

### 🎯 Creative Performance Analysis
- *"What are the top performing creative formats by audience segment?"*
- *"Show me creative sentiment impact on engagement rates"*  
- *"Which lifestyle creatives perform best with millennials?"*
- *"Compare banner vs video performance across age groups"*

### 📊 Audience Intelligence
- *"Which audience segments have the highest engagement rates?"*
- *"Find high-value lookalike segments for luxury fashion campaigns"*
- *"Show demographic distribution of our highest converting audiences"*
- *"Analyze opt-in vs opt-out audience performance differences"*

### 🔄 Attribution Modeling  
- *"Map customer journeys from awareness to conversion across channels"*
- *"Show me attribution paths for high-value conversions"*
- *"Which touchpoint sequences drive the most conversions?"*
- *"Analyze cross-channel attribution for streaming campaigns"*

### 🔒 Privacy & Compliance
- *"How does consent status affect campaign performance?"*
- *"Show privacy compliance status across demographics"* 
- *"Which audiences have PII data and opted-in consent?"*

### 💰 ROI & Performance
- *"Compare ROI performance across different media channels"*
- *"Which campaigns generated the highest return on investment?"*
- *"Show cost-per-conversion by audience segment"*

## 🎪 Demo Scenarios

Perfect for demonstrating modern media analytics capabilities to stakeholders, clients, and teams.

## 📊 Performance Benchmarks

### Expected Query Performance
- **Simple lookups:** < 10ms (with proper indexing)
- **Cross-table joins:** < 100ms for most analytical queries  
- **Complex aggregations:** < 500ms for dashboard refreshes
- **Full dataset scans:** < 2s for reporting queries

### Recommended Indexes
```sql
-- High-impact indexes for common queries
CREATE INDEX idx_performance_segment_creative ON campaign_performance(segment_id, creative_id);
CREATE INDEX idx_segments_interest ON audience_segments(primary_interest, secondary_interest);  
CREATE INDEX idx_attribution_campaign_audience ON attribution_events(campaign_id, audience_id);
```

## 🚀 Next Steps

### Recommended: Snowflake Intelligence Setup
1. **Execute Setup Script:** Run `scripts/snowflake_setup.sql` in Snowflake for complete AI-powered analytics
2. **Access AI Agent:** Use Snowflake Intelligence for natural language queries
3. **Demo & Explore:** Leverage the AI agent for audience insights and creative optimization

### Alternative: Manual Setup
1. **Import Data:** Use provided SQL scripts in `/scripts` folder to set up your database
2. **Explore Queries:** Run `scripts/sample_analytics_queries.sql` to understand the data structure
3. **Build Dashboards:** Connect your BI tools for visualization  
4. **Customize Analysis:** Modify queries for your specific use cases
5. **Extend Dataset:** Use `scripts/generate_audience_data.py` to create additional data

## 📞 Support

This dataset was created for demonstration purposes and includes realistic but simulated data. All image URLs, audience profiles, and performance metrics are generated for testing and should not be considered real user data or actual campaign results.

### 🛠️ **Customization**

The included Python scripts in `/scripts` folder can be modified to generate additional data with different parameters:
- Adjust audience counts, segment distributions, or geographic targeting
- Modify creative formats, content types, or sentiment distributions  
- Change campaign performance ranges, channel mix, or attribution models
- Add new interest categories, demographic segments, or privacy scenarios

### 📞 **Repository & Support**

- **GitHub Repository**: [https://github.com/sfc-gh-bciranni/audience-analytics-demo](https://github.com/sfc-gh-bciranni/audience-analytics-demo)
- **Setup Instructions**: See `docs/github_setup_instructions.md` for detailed deployment steps
- **Data Generation**: Run `scripts/generate_audience_data.py` to create fresh datasets
- **Data Validation**: Run `scripts/data_summary_report.py` to analyze existing data

---

**Generated by:** Media Agency Demo Data Generator  
**Version:** 1.0  
**Date:** 2024  
**Total Records:** 24,106 across 7 tables
