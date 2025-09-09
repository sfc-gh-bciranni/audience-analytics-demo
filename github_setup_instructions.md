# GitHub Repository Setup Instructions

## Repository Setup for Snowflake Integration

To set up the GitHub repository for Snowflake Git integration, follow these steps:

### 1. Create GitHub Repository

1. Go to GitHub and create a new public repository named `audience-analytics-demo`
2. Repository URL should be: `https://github.com/sfc-gh-bciranni/audience-analytics-demo`
3. Make sure the repository is **public** (required for Git integration)

### 2. Upload Data Files

Upload all the CSV files to the **root directory** of your repository (not in a subfolder):

```
audience-analytics-demo/
├── audience_demographics.csv
├── audience_segments.csv  
├── creative_metadata.csv
├── media_channel_engagement.csv
├── campaign_performance.csv
├── attribution_events.csv
├── consent_privacy.csv
├── README.md
├── create_database_schema.sql
├── sample_analytics_queries.sql
└── snowflake_setup.sql
```

### 3. Repository Structure Required

The Snowflake setup script expects files in the main branch root directory. **Do not create a demo_data subdirectory** - place CSV files directly in the repository root.

### 4. Verification

After uploading, verify your repository structure matches:
- All 7 CSV files are in the root directory
- Repository is public and accessible
- Main branch contains all files

### 5. Snowflake Setup

Once the repository is ready:

1. Copy the contents of `snowflake_setup.sql`
2. Execute the script in a Snowflake worksheet
3. The script will:
   - Create the necessary roles and permissions
   - Set up Git integration with your repository
   - Create database, schema, and tables
   - Load all data automatically from GitHub
   - Create semantic views for Cortex Analyst
   - Set up the Snowflake Intelligence Agent

### 6. Access Your Agent

After setup completes:

1. Go to Snowflake's AI/ML section
2. Select "Snowflake Intelligence"  
3. Choose the "Media Agency Audience Analytics Agent"
4. Start exploring your audience data with natural language queries!

### Sample Questions for Your Agent

- "What are the top performing creative formats by audience segment?"
- "Show me attribution paths for high-value conversions"  
- "Which audience segments have the highest engagement rates across channels?"
- "Compare ROI performance across different media channels"
- "Analyze creative sentiment impact on campaign performance"
- "Show privacy consent status distribution across demographics"

### Troubleshooting

If the Git integration fails:
- Ensure repository is public
- Verify all CSV files are in the root directory (not subfolders)
- Check that file names match exactly what the script expects
- Make sure you have the correct repository URL format

### Repository Contents

Your final repository should include:
- **7 CSV data files** (24,106 total records)
- **Documentation files** (README, setup instructions)
- **SQL scripts** (schema creation, sample queries, Snowflake setup)
- **Python generators** (for creating additional data if needed)

This setup provides a complete audience analytics environment with:
- 1,200 audience demographics
- 3,020 audience segments  
- 1,500 creative assets with metadata
- 5,000 campaign performance records
- 8,000 attribution events
- Complete privacy compliance tracking
