#!/usr/bin/env python3
"""
SQL Schema Validation Script
Validates that semantic view column references match actual table schemas
to prevent case mismatch errors in Snowflake.
"""

import re
import os

def extract_table_columns(sql_content):
    """Extract table definitions and their column names from SQL"""
    tables = {}
    
    # Find all CREATE TABLE statements
    table_pattern = r'CREATE OR REPLACE TABLE (\w+) \((.*?)\);'
    matches = re.findall(table_pattern, sql_content, re.DOTALL | re.IGNORECASE)
    
    for table_name, columns_def in matches:
        columns = []
        # Extract column definitions
        column_lines = columns_def.split('\n')
        for line in column_lines:
            line = line.strip()
            if line and not line.startswith('--') and not line.startswith('FOREIGN KEY'):
                # Extract column name (first word before space or parenthesis)
                column_match = re.match(r'(\w+)', line)
                if column_match:
                    columns.append(column_match.group(1))
        
        tables[table_name.lower()] = columns
    
    return tables

def extract_semantic_view_references(sql_content):
    """Extract column references from semantic views"""
    references = []
    
    # Find all semantic view sections
    semantic_pattern = r'CREATE OR REPLACE SEMANTIC VIEW.*?(?=CREATE|$)'
    matches = re.findall(semantic_pattern, sql_content, re.DOTALL | re.IGNORECASE)
    
    for match in matches:
        # Find table alias to column references like DEMOGRAPHICS.column_name
        ref_pattern = r'(\w+)\.(\w+)'
        refs = re.findall(ref_pattern, match)
        references.extend(refs)
    
    return references

def validate_column_references(sql_file_path):
    """Validate that semantic view column references match table schemas"""
    print(f"🔍 Validating SQL schema: {sql_file_path}")
    
    with open(sql_file_path, 'r') as f:
        sql_content = f.read()
    
    # Extract table schemas
    tables = extract_table_columns(sql_content)
    print(f"📊 Found {len(tables)} tables:")
    for table, cols in tables.items():
        print(f"  - {table}: {len(cols)} columns")
    
    # Extract semantic view references
    references = extract_semantic_view_references(sql_content)
    print(f"🔗 Found {len(references)} column references in semantic views")
    
    # Map table aliases to actual table names
    alias_mapping = {
        'demographics': 'audience_demographics',
        'segments': 'audience_segments', 
        'creatives': 'creative_metadata',
        'performance': 'campaign_performance',
        'attribution': 'attribution_events',
        'engagement': 'media_channel_engagement',
        'consent': 'consent_privacy'
    }
    
    errors = []
    warnings = []
    
    for alias, column in references:
        alias_lower = alias.lower()
        
        # Skip if it's a computed metric or function
        if column.upper() in ['COUNT', 'SUM', 'AVG', 'MAX', 'MIN'] or \
           column.lower() in ['total_segments', 'total_audiences', 'lookalike_segments', 
                              'opt_in_audiences', 'total_impressions', 'total_clicks',
                              'total_conversions', 'total_cost', 'average_roi', 'average_ctr',
                              'average_sentiment', 'total_attribution_events', 'average_attribution',
                              'total_reach', 'average_frequency', 'average_engagement_rate']:
            continue
            
        # Get actual table name
        table_name = alias_mapping.get(alias_lower, alias_lower)
        
        if table_name in tables:
            actual_columns = tables[table_name]
            
            # Check if column exists (case-sensitive)
            if column not in actual_columns:
                # Check if it exists with different case
                column_lower = column.lower()
                matching_columns = [col for col in actual_columns if col.lower() == column_lower]
                
                if matching_columns:
                    correct_column = matching_columns[0]
                    errors.append(f"❌ Case mismatch: {alias}.{column} should be {alias}.{correct_column}")
                else:
                    warnings.append(f"⚠️  Column not found: {alias}.{column} in table {table_name}")
        else:
            warnings.append(f"⚠️  Table not found: {table_name} for alias {alias}")
    
    # Print results
    print(f"\n{'='*60}")
    print("VALIDATION RESULTS")
    print(f"{'='*60}")
    
    if errors:
        print(f"❌ ERRORS FOUND ({len(errors)}):")
        for error in errors:
            print(f"  {error}")
    else:
        print("✅ No case mismatch errors found!")
    
    if warnings:
        print(f"\n⚠️  WARNINGS ({len(warnings)}):")
        for warning in warnings:
            print(f"  {warning}")
    
    print(f"\n📈 SUMMARY:")
    print(f"  - Tables analyzed: {len(tables)}")
    print(f"  - Column references checked: {len([r for r in references if r[1] not in ['COUNT', 'SUM', 'AVG']])}")
    print(f"  - Errors: {len(errors)}")
    print(f"  - Warnings: {len(warnings)}")
    
    return len(errors) == 0

def main():
    """Main validation function"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sql_file = os.path.join(script_dir, 'snowflake_setup.sql')
    
    if not os.path.exists(sql_file):
        print(f"❌ SQL file not found: {sql_file}")
        return False
    
    success = validate_column_references(sql_file)
    
    if success:
        print("\n🎉 VALIDATION PASSED - SQL schema is consistent!")
        return True
    else:
        print("\n💥 VALIDATION FAILED - Please fix the errors above")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
