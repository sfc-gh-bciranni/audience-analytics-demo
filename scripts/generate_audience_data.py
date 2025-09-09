#!/usr/bin/env python3
"""
Media Agency Audience Analytics Demo Data Generator
Generates realistic sample data for audience exploration tool demo
"""

import random
import csv
import os
from datetime import datetime, timedelta
from faker import Faker
import uuid

fake = Faker()
Faker.seed(42)  # For reproducible results
random.seed(42)

# Configuration
NUM_AUDIENCES = 1200
NUM_SEGMENTS = 2500  # Multiple segments per audience
NUM_CREATIVES = 1500
NUM_CAMPAIGNS = 400
NUM_ENGAGEMENTS = 3000  # Multiple channels per audience
NUM_CAMPAIGN_PERFORMANCES = 5000
NUM_ATTRIBUTION_EVENTS = 8000
NUM_CONSENT_RECORDS = 1200  # One per audience

# Data constants
AGE_GROUPS = ["18-24", "25-34", "35-44", "45-54", "55-64", "65+"]
GENDERS = ["Male", "Female", "Non-binary", "Prefer not to say"]
INCOME_RANGES = ["<$25k", "$25k-$50k", "$50k-$75k", "$75k-$100k", "$100k-$150k", "$150k+"]
EDUCATION_LEVELS = ["High School", "Some College", "Bachelor's", "Master's", "Doctorate", "Trade School"]
ETHNICITIES = ["White", "Black/African American", "Hispanic/Latino", "Asian", "Native American", "Mixed", "Other"]

STATES = ["CA", "TX", "FL", "NY", "PA", "IL", "OH", "GA", "NC", "MI", "NJ", "VA", "WA", "AZ", "MA", "TN", "IN", "MD", "MO", "WI"]
CITIES = {
    "CA": ["Los Angeles", "San Francisco", "San Diego", "Sacramento"],
    "TX": ["Houston", "Dallas", "Austin", "San Antonio"],
    "NY": ["New York City", "Albany", "Buffalo", "Rochester"],
    "FL": ["Miami", "Orlando", "Tampa", "Jacksonville"]
}

INTERESTS_PRIMARY = [
    "Fashion & Beauty", "Technology", "Travel", "Food & Dining", "Sports", "Entertainment",
    "Health & Wellness", "Home & Garden", "Automotive", "Finance", "Education", "Gaming",
    "Music", "Art & Culture", "Outdoor Activities", "Fitness", "Parenting", "Pets",
    "Real Estate", "Business", "Politics", "Environment", "Science", "Books"
]

INTERESTS_SECONDARY = [
    "Luxury Goods", "Budget Shopping", "Eco-Friendly", "DIY Projects", "Social Causes",
    "Celebrity News", "Investment", "Career Development", "Local Events", "International News",
    "Photography", "Cooking", "Streaming", "Mobile Apps", "E-commerce", "Social Media"
]

CHANNELS = ["TV", "Streaming", "Digital", "Social", "Retail", "Radio", "Print", "OOH", "Email"]
CREATIVE_FORMATS = ["Banner", "Video", "Native", "Rich Media", "Audio", "Display", "Social Post", "CTV"]
CONTENT_TYPES = ["Product Shot", "Lifestyle", "Promotional", "Educational", "User Generated", "Brand Story", "Testimonial"]

TOUCHPOINT_TYPES = ["View", "Click", "Impression", "Engagement", "Conversion", "Share", "Comment"]
CONSENT_STATUSES = ["Opt-in", "Opt-out", "Pending", "Expired"]

def generate_audience_demographics():
    """Generate realistic audience demographics data"""
    print("Generating Audience Demographics...")
    audiences = []
    
    for i in range(1, NUM_AUDIENCES + 1):
        # Generate realistic geographic distribution
        state = random.choice(STATES)
        city = random.choice(CITIES.get(state, [fake.city()]))
        
        audience = {
            'audience_id': f'AUD_{i:06d}',
            'age_group': random.choice(AGE_GROUPS),
            'gender': random.choice(GENDERS),
            'state': state,
            'city': city,
            'country': 'USA',
            'household_income': random.choice(INCOME_RANGES),
            'education_level': random.choice(EDUCATION_LEVELS),
            'ethnicity': random.choice(ETHNICITIES)
        }
        audiences.append(audience)
    
    return audiences

def generate_audience_segments(audiences):
    """Generate audience segments with multiple segments per audience"""
    print("Generating Audience Segments...")
    segments = []
    segment_counter = 1
    
    for audience in audiences:
        # Each audience can belong to 1-4 segments
        num_segments = random.randint(1, 4)
        
        for _ in range(num_segments):
            segment = {
                'segment_id': f'SEG_{segment_counter:06d}',
                'audience_id': audience['audience_id'],
                'segment_name': f"{random.choice(['Premium', 'Value', 'Emerging', 'Core', 'Niche'])} {random.choice(INTERESTS_PRIMARY)} Enthusiasts",
                'primary_interest': random.choice(INTERESTS_PRIMARY),
                'secondary_interest': random.choice(INTERESTS_SECONDARY),
                'lookalike_segment_flag': random.choice([True, False])
            }
            segments.append(segment)
            segment_counter += 1
    
    return segments

def generate_creative_metadata():
    """Generate creative metadata with realistic image data"""
    print("Generating Creative Metadata...")
    creatives = []
    
    for i in range(1, NUM_CREATIVES + 1):
        creative_format = random.choice(CREATIVE_FORMATS)
        content_type = random.choice(CONTENT_TYPES)
        
        # Generate realistic image tags based on content type
        base_tags = {
            "Product Shot": ["product", "clean", "minimalist", "brand"],
            "Lifestyle": ["people", "lifestyle", "authentic", "emotional"],
            "Promotional": ["sale", "discount", "offer", "urgent"],
            "Educational": ["informative", "tutorial", "how-to", "expert"],
            "User Generated": ["real", "community", "user", "authentic"],
            "Brand Story": ["heritage", "story", "values", "mission"],
            "Testimonial": ["review", "customer", "satisfaction", "trust"]
        }
        
        tags = base_tags.get(content_type, ["generic"])
        additional_tags = random.sample(["colorful", "bold", "subtle", "modern", "classic", "trendy", "professional"], k=random.randint(1, 3))
        all_tags = tags + additional_tags
        
        creative = {
            'creative_id': f'CRE_{i:06d}',
            'image_url': f'https://demo-assets.media-agency.com/creatives/CRE_{i:06d}.{random.choice(["jpg", "png", "mp4", "gif"])}',
            'creative_format': creative_format,
            'content_type': content_type,
            'image_tags': ','.join(all_tags),
            'sentiment_score': round(random.uniform(-0.8, 0.9), 2),  # Slightly positive bias
            'audit_status': random.choices(['Approved', 'Pending', 'Rejected', 'Under Review'], weights=[70, 15, 5, 10])[0],
            'created_date': fake.date_between(start_date=datetime.now() - timedelta(days=730), end_date=datetime.now()).strftime('%Y-%m-%d'),
            'campaign_id': None  # Will be populated when generating campaigns
        }
        creatives.append(creative)
    
    return creatives

def generate_campaigns_and_link_creatives(segments, creatives):
    """Generate campaigns and link them to creatives"""
    print("Generating Campaigns and linking to Creatives...")
    campaigns = []
    
    # Create campaigns
    for i in range(1, NUM_CAMPAIGNS + 1):
        campaign = {
            'campaign_id': f'CAM_{i:06d}',
            'campaign_name': f"{random.choice(['Q1', 'Q2', 'Q3', 'Q4'])} {random.choice(['Brand Awareness', 'Product Launch', 'Conversion', 'Retargeting'])} Campaign",
            'start_date': fake.date_between(start_date=datetime.now() - timedelta(days=365), end_date=datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d'),
            'end_date': fake.date_between(start_date=datetime.now() - timedelta(days=29), end_date=datetime.now()).strftime('%Y-%m-%d'),
            'budget': random.randint(10000, 500000),
            'status': random.choice(['Active', 'Completed', 'Paused'])
        }
        campaigns.append(campaign)
    
    # Assign creatives to campaigns - distribute evenly with some campaigns getting more
    creatives_per_campaign = len(creatives) // len(campaigns)
    extra_creatives = len(creatives) % len(campaigns)
    
    creative_index = 0
    for i, campaign in enumerate(campaigns):
        # Some campaigns get an extra creative
        num_creatives_for_campaign = creatives_per_campaign + (1 if i < extra_creatives else 0)
        num_creatives_for_campaign = max(1, num_creatives_for_campaign)  # Ensure at least 1 creative per campaign
        
        for j in range(num_creatives_for_campaign):
            if creative_index < len(creatives):
                creatives[creative_index]['campaign_id'] = campaign['campaign_id']
                creative_index += 1
            else:
                # If we run out, assign random campaign
                random_creative = random.choice(creatives)
                random_creative['campaign_id'] = campaign['campaign_id']
    
    return campaigns

def generate_media_channel_engagement(audiences):
    """Generate media channel engagement data"""
    print("Generating Media Channel Engagement...")
    engagements = []
    engagement_counter = 1
    
    for audience in audiences:
        # Each audience engages with 2-5 different channels
        num_channels = random.randint(2, 5)
        selected_channels = random.sample(CHANNELS, num_channels)
        
        for channel in selected_channels:
            # Generate realistic metrics based on channel type
            base_impressions = {
                'TV': (50000, 200000),
                'Streaming': (10000, 80000),
                'Digital': (5000, 50000),
                'Social': (1000, 25000),
                'Retail': (500, 5000)
            }
            
            imp_range = base_impressions.get(channel, (1000, 20000))
            impressions = random.randint(*imp_range)
            reach = int(impressions * random.uniform(0.6, 0.9))
            frequency = round(impressions / reach if reach > 0 else 1, 2)
            
            # Engagement rates vary by channel
            engagement_rates = {
                'Social': (0.02, 0.08),
                'Digital': (0.01, 0.05),
                'Streaming': (0.005, 0.02),
                'TV': (0.001, 0.01)
            }
            
            eng_range = engagement_rates.get(channel, (0.001, 0.03))
            engagement_rate = round(random.uniform(*eng_range), 4)
            
            engagement = {
                'engagement_id': f'ENG_{engagement_counter:06d}',
                'audience_id': audience['audience_id'],
                'channel_type': channel,
                'impressions': impressions,
                'reach': reach,
                'frequency': frequency,
                'engagement_rate': engagement_rate
            }
            engagements.append(engagement)
            engagement_counter += 1
    
    return engagements

def generate_campaign_performance(segments, creatives):
    """Generate campaign performance data"""
    print("Generating Campaign Performance...")
    performances = []
    
    for i in range(1, NUM_CAMPAIGN_PERFORMANCES + 1):
        segment = random.choice(segments)
        creative = random.choice(creatives)
        channel = random.choice(CHANNELS)
        
        # Generate realistic performance metrics
        impressions = random.randint(1000, 100000)
        ctr_base = {
            'Social': 0.025,
            'Digital': 0.015,
            'Email': 0.035,
            'Search': 0.02
        }
        
        ctr = random.uniform(0.005, ctr_base.get(channel, 0.02))
        clicks = int(impressions * ctr)
        conversion_rate = random.uniform(0.01, 0.05)
        conversions = int(clicks * conversion_rate)
        
        # Cost varies by channel
        cpm_ranges = {
            'TV': (15, 40),
            'Digital': (2, 8),
            'Social': (5, 15),
            'Streaming': (10, 25)
        }
        
        cpm = random.uniform(*cpm_ranges.get(channel, (2, 10)))
        cost = (impressions / 1000) * cpm
        
        roi = (conversions * random.uniform(50, 200) - cost) / cost if cost > 0 else 0
        
        performance = {
            'performance_id': f'PERF_{i:06d}',
            'campaign_id': creative['campaign_id'],
            'segment_id': segment['segment_id'],
            'creative_id': creative['creative_id'],
            'media_channel': channel,
            'impressions': impressions,
            'clicks': clicks,
            'conversions': conversions,
            'cost': round(cost, 2),
            'ROI': round(roi, 2),
            'CTR': round(ctr, 4)
        }
        performances.append(performance)
    
    return performances

def generate_attribution_events(campaigns, audiences):
    """Generate attribution events data"""
    print("Generating Attribution Events...")
    events = []
    
    for i in range(1, NUM_ATTRIBUTION_EVENTS + 1):
        campaign = random.choice(campaigns)
        audience = random.choice(audiences)
        
        # Generate realistic timestamp within campaign period
        start_date = datetime.strptime(campaign['start_date'], '%Y-%m-%d')
        end_date = datetime.strptime(campaign['end_date'], '%Y-%m-%d')
        event_time = fake.date_time_between(start_date=start_date, end_date=end_date)
        
        event = {
            'attribution_id': f'ATTR_{i:06d}',
            'campaign_id': campaign['campaign_id'],
            'audience_id': audience['audience_id'],
            'media_channel': random.choice(CHANNELS),
            'timestamp': event_time.strftime('%Y-%m-%d %H:%M:%S'),
            'touchpoint_type': random.choice(TOUCHPOINT_TYPES),
            'attribution_percent': round(random.uniform(0.1, 1.0), 2),
            'benchmark': round(random.uniform(0.05, 0.8), 2)
        }
        events.append(event)
    
    return events

def generate_consent_privacy(audiences):
    """Generate consent and privacy data"""
    print("Generating Consent Privacy...")
    consents = []
    
    for i, audience in enumerate(audiences, 1):
        consent = {
            'consent_id': f'CONS_{i:06d}',
            'audience_id': audience['audience_id'],
            'consent_status': random.choices(CONSENT_STATUSES, weights=[70, 15, 10, 5])[0],
            'PII_flag': random.choice([True, False]),
            'privacy_signal_timestamp': fake.date_time_between(start_date=datetime.now() - timedelta(days=730), end_date=datetime.now()).strftime('%Y-%m-%d %H:%M:%S'),
            'last_updated': fake.date_time_between(start_date=datetime.now() - timedelta(days=30), end_date=datetime.now()).strftime('%Y-%m-%d %H:%M:%S')
        }
        consents.append(consent)
    
    return consents

def write_to_csv(data, filename, fieldnames):
    """Write data to CSV file"""
    # Get the parent directory (project root) and ensure data directory exists
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_dir = os.path.join(project_root, 'data')
    os.makedirs(data_dir, exist_ok=True)
    filepath = os.path.join(data_dir, filename)
    with open(filepath, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)
    print(f"✓ Written {len(data)} records to {filename}")

def main():
    """Generate all sample data"""
    print("🚀 Starting Media Agency Audience Data Generation...")
    print(f"Target: {NUM_AUDIENCES} audiences, {NUM_SEGMENTS} segments, {NUM_CREATIVES} creatives")
    print("=" * 60)
    
    # Generate core data
    audiences = generate_audience_demographics()
    segments = generate_audience_segments(audiences)
    creatives = generate_creative_metadata()
    campaigns = generate_campaigns_and_link_creatives(segments, creatives)
    engagements = generate_media_channel_engagement(audiences)
    performances = generate_campaign_performance(segments, creatives)
    attribution_events = generate_attribution_events(campaigns, audiences)
    consents = generate_consent_privacy(audiences)
    
    # Write to CSV files
    print("\n📊 Writing data to CSV files...")
    
    write_to_csv(audiences, 'audience_demographics.csv', 
                 ['audience_id', 'age_group', 'gender', 'state', 'city', 'country', 'household_income', 'education_level', 'ethnicity'])
    
    write_to_csv(segments, 'audience_segments.csv',
                 ['segment_id', 'audience_id', 'segment_name', 'primary_interest', 'secondary_interest', 'lookalike_segment_flag'])
    
    write_to_csv(creatives, 'creative_metadata.csv',
                 ['creative_id', 'image_url', 'creative_format', 'content_type', 'image_tags', 'sentiment_score', 'audit_status', 'created_date', 'campaign_id'])
    
    write_to_csv(engagements, 'media_channel_engagement.csv',
                 ['engagement_id', 'audience_id', 'channel_type', 'impressions', 'reach', 'frequency', 'engagement_rate'])
    
    write_to_csv(performances, 'campaign_performance.csv',
                 ['performance_id', 'campaign_id', 'segment_id', 'creative_id', 'media_channel', 'impressions', 'clicks', 'conversions', 'cost', 'ROI', 'CTR'])
    
    write_to_csv(attribution_events, 'attribution_events.csv',
                 ['attribution_id', 'campaign_id', 'audience_id', 'media_channel', 'timestamp', 'touchpoint_type', 'attribution_percent', 'benchmark'])
    
    write_to_csv(consents, 'consent_privacy.csv',
                 ['consent_id', 'audience_id', 'consent_status', 'PII_flag', 'privacy_signal_timestamp', 'last_updated'])
    
    print("\n" + "=" * 60)
    print("🎉 Data generation complete!")
    print(f"✓ {len(audiences)} audience demographics")
    print(f"✓ {len(segments)} audience segments")
    print(f"✓ {len(creatives)} creative metadata records")
    print(f"✓ {len(engagements)} media channel engagements")
    print(f"✓ {len(performances)} campaign performance records")
    print(f"✓ {len(attribution_events)} attribution events")
    print(f"✓ {len(consents)} consent/privacy records")
    # Get the project root and data directory for display
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_dir = os.path.join(project_root, 'data')
    print(f"\nFiles generated in {data_dir}/")

if __name__ == "__main__":
    main()
