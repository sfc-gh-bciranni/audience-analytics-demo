# SQL Schema Validation Guide

## Overview

This guide provides a systematic approach to prevent SQL compilation errors related to column name case mismatches in Snowflake semantic views.

## The Problem

Snowflake semantic views are case-sensitive when referencing table columns. If a semantic view references `DEMOGRAPHICS.EDUCATION_LEVEL` but the actual table column is `education_level` (lowercase), you'll get compilation errors like:

```
SQL compilation error: error line 301 at position 40 invalid identifier 'EDUCATION'
```

## Prevention Strategy

### 1. Use the Validation Script

We've created an automated validation script that checks for case mismatches:

```bash
# Run from the scripts directory
python validate_sql_schema.py
```

**Output Example:**
```
🔍 Validating SQL schema: snowflake_setup.sql
📊 Found 7 tables: 90+ column references checked
✅ No case mismatch errors found!
🎉 VALIDATION PASSED - SQL schema is consistent!
```

### 2. Run Before Every Deploy

**Always run validation before pushing SQL changes:**

```bash
# Pre-deployment checklist
cd scripts/
python validate_sql_schema.py

# Only proceed if validation passes
git add .
git commit -m "Your changes"
git push origin main
```

### 3. Case Matching Rules

**Table Schema (lowercase):**
```sql
CREATE TABLE audience_demographics (
    audience_id VARCHAR(10),
    age_group VARCHAR(10),
    household_income VARCHAR(15),
    education_level VARCHAR(20)
);
```

**Semantic View References (must match exactly):**
```sql
-- ✅ CORRECT
DEMOGRAPHICS.audience_id
DEMOGRAPHICS.age_group  
DEMOGRAPHICS.household_income
DEMOGRAPHICS.education_level

-- ❌ INCORRECT
DEMOGRAPHICS.AUDIENCE_ID
DEMOGRAPHICS.AGE_GROUP
DEMOGRAPHICS.HOUSEHOLD_INCOME
DEMOGRAPHICS.EDUCATION_LEVEL
```

**Special Cases (uppercase in schema):**
```sql
-- These columns are actually uppercase in the schema
PERFORMANCE.ROI  -- ✅ Correct
PERFORMANCE.CTR  -- ✅ Correct  
CONSENT.PII_flag -- ✅ Correct
```

### 4. Common Case Mismatch Patterns

| Error Pattern | Correct Reference | Notes |
|---------------|-------------------|-------|
| `EDUCATION_LEVEL` → `education_level` | Column names are lowercase |
| `HOUSEHOLD_INCOME` → `household_income` | Standard lowercase pattern |
| `SEGMENT_NAME` → `segment_name` | Consistent with table schema |
| `performance.roi` → `performance.ROI` | ROI/CTR are uppercase exceptions |

## Validation Script Details

### What It Checks
- **Table Schemas**: Extracts actual column names from `CREATE TABLE` statements
- **Semantic Views**: Finds all column references in semantic view definitions  
- **Case Sensitivity**: Compares references against actual table columns
- **Comprehensive Coverage**: Validates all 7 tables and 90+ column references

### Sample Output
```bash
🔍 Validating SQL schema: snowflake_setup.sql
📊 Found 7 tables:
  - audience_demographics: 10 columns
  - campaign_performance: 12 columns
  - creative_metadata: 10 columns
  
❌ ERRORS FOUND (2):
  ❌ Case mismatch: DEMOGRAPHICS.EDUCATION_LEVEL should be DEMOGRAPHICS.education_level
  ❌ Case mismatch: performance.roi should be performance.ROI

✅ Result: Fix these 2 errors before deploying
```

### How It Works
1. **Parses SQL**: Extracts table definitions using regex patterns
2. **Maps Aliases**: Links semantic view table aliases to actual table names
3. **Validates References**: Compares each column reference against table schema
4. **Reports Issues**: Shows exact mismatches with suggested corrections

## Integration in Workflow

### Development Process
```bash
1. Make SQL changes
2. Run validation: python scripts/validate_sql_schema.py  
3. Fix any errors reported
4. Re-run validation until ✅ passes
5. Commit and deploy
```

### CI/CD Integration
Add to your deployment pipeline:
```yaml
- name: Validate SQL Schema
  run: |
    cd scripts
    python validate_sql_schema.py
  # Only proceed if validation passes
```

## Common Fixes Applied

### Before (Error-prone)
```sql
-- These caused compilation errors
DEMOGRAPHICS.EDUCATION_LEVEL    ❌
DEMOGRAPHICS.HOUSEHOLD_INCOME   ❌  
SEGMENTS.SEGMENT_NAME          ❌
PERFORMANCE.CAMPAIGN_COST      ❌
```

### After (Fixed)
```sql
-- Corrected to match table schema
DEMOGRAPHICS.education_level    ✅
DEMOGRAPHICS.household_income   ✅
SEGMENTS.segment_name          ✅  
PERFORMANCE.cost               ✅
```

## Benefits

- **Prevents Errors**: Catches case mismatches before deployment
- **Saves Time**: No more trial-and-error debugging of SQL compilation errors
- **Systematic**: Validates entire schema consistently  
- **Automated**: Integrates into development workflow
- **Comprehensive**: Covers all tables and semantic views

## Summary

The validation script ensures that your Snowflake semantic views will compile successfully by systematically checking column name case sensitivity. This prevents the frustrating "invalid identifier" errors and ensures a smooth deployment process.

**Remember**: Always run `python scripts/validate_sql_schema.py` before deploying SQL changes!
