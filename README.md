# Audience Analytics Demo for Snowflake Intelligence

A comprehensive, realistic dataset and Snowflake Intelligence setup for demonstrating audience analytics, creative performance optimization, and cross-channel attribution for media agencies.

## 🚀 Quick Start

**Just copy and paste - that's it!**

1. **Copy the Setup Script**:
   - Open `scripts/snowflake_setup.sql` 
   - Copy the entire contents (Ctrl+A, Ctrl+C)

2. **Run in Snowflake**:
   - Open a new worksheet in Snowflake
   - Paste the script (Ctrl+V)
   - Click "Run All" or press Ctrl+Shift+Enter
   - Wait ~2-3 minutes for complete setup

3. **Start Using Your AI Agent**:
   ```
   "Show me the top performing creative formats by conversion rate"
   "Which audience segments have the highest engagement rates?"  
   "What's the attribution breakdown for our digital campaigns?"
   "Find audiences similar to our best converting segments"
   ```

**That's it!** The script automatically:
- ✅ Creates database and schema
- ✅ Loads 24,000+ realistic sample records 
- ✅ Sets up 3 semantic views for natural language queries
- ✅ Creates an AI agent with web scraping and email capabilities
- ✅ Configures all permissions and integrations

---

## 📊 What You Get

**24,000+ realistic records** across 7 interconnected tables:

- **1,200 audience profiles** with demographics, geography, income, education
- **3,000 audience segments** with interests and lookalike modeling
- **1,500 creative assets** with sentiment analysis and performance tags
- **4,200 channel engagement metrics** across TV, Digital, Social, Streaming
- **5,000 campaign performance records** linking audiences to creatives
- **8,000 attribution events** for cross-channel journey analysis
- **1,200 privacy consent records** for GDPR/CCPA compliance

### 🎯 Demo Capabilities

- **Natural Language Queries**: Ask questions in plain English
- **Cross-Channel Attribution**: Understand customer journeys
- **Creative Performance**: Optimize ads based on sentiment and engagement  
- **Audience Segmentation**: Find lookalike audiences and high-value segments
- **Privacy Compliance**: Track consent and PII usage
- **Web Scraping**: Analyze external content and competitors
- **Email Notifications**: Get insights delivered automatically

---

## 🤖 What Your AI Agent Can Do

**Ask questions like:**
- "Which demographic segments have the highest lifetime value?"
- "Show me lookalike audiences for my top converting segments"  
- "Which creative formats perform best for millennial audiences?"
- "What's the average customer journey for converted users?"
- "How many users have opted out of data collection this month?"
- "Find creatives with high sentiment scores but low conversion rates"
- "Which channels contribute most to conversions in the first 7 days?"
- "Email me a weekly summary of campaign performance"
- "Scrape competitor landing pages and analyze their messaging"

---

## 📁 What's Included

```
audience-analytics-demo/
├── scripts/snowflake_setup.sql     # 🎯 THE ONLY FILE YOU NEED
├── data/                          # Sample CSV files (auto-loaded)
└── README.md                      # This guide
```

---

## 📋 Sample Queries (Optional)

Once set up, you can also run traditional SQL:

```sql
-- Top performing demographics by conversion rate
SELECT 
    d.age_group, d.household_income,
    AVG(p.CTR) as avg_ctr, AVG(p.ROI) as avg_roi
FROM audience_demographics d
JOIN audience_segments s ON d.audience_id = s.audience_id  
JOIN campaign_performance p ON s.segment_id = p.segment_id
GROUP BY d.age_group, d.household_income
ORDER BY avg_roi DESC;

-- Creative sentiment vs performance correlation
SELECT 
    c.creative_format,
    AVG(c.sentiment_score) as avg_sentiment,
    AVG(p.CTR) as avg_ctr
FROM creative_metadata c
JOIN campaign_performance p ON c.creative_id = p.creative_id
GROUP BY c.creative_format
ORDER BY avg_ctr DESC;
```

But the **AI agent is much easier** - just ask in plain English!

---

## 🤝 Need Help?

**Having issues?** The script handles everything automatically, but if something goes wrong:

1. **Check your Snowflake role** - Make sure you have ACCOUNTADMIN privileges
2. **Run the script again** - All commands use `CREATE OR REPLACE` so it's safe to re-run
3. **Check the data** - Query any table to verify your 24K records loaded successfully

---

## 📜 License

Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

**Ready to explore your audience data with AI?** Just copy, paste, and run! 🚀