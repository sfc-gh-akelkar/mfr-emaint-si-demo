-- ============================================================================
-- STERIS "Factory of the Future" AI Reliability Platform
-- MASTER SETUP SCRIPT
-- ============================================================================
-- This script orchestrates the complete setup of the STERIS eMaint demo.
-- Simply run the SQL scripts in order - no CSV uploads required!
-- ============================================================================

-- ============================================================================
-- PREREQUISITES:
-- 1. You must have the SF_INTELLIGENCE_DEMO role with appropriate privileges
-- 2. Snowflake Intelligence features must be enabled on your account
-- ============================================================================

-- Step 1: Create Database and Schemas
-- Run: sql/01_setup_database.sql

-- Step 2: Create Raw Tables and Insert Data (all data embedded in SQL)
-- Run: sql/02_create_raw_tables.sql

-- Step 3: Create Curated Views
-- Run: sql/03_create_curated_views.sql

-- Step 4: Create Semantic View for Cortex Analyst
-- Run: sql/04_create_semantic_view.sql

-- Step 5: Create Cortex Search Service
-- Run: sql/05_create_cortex_search.sql

-- Step 6: Create Cortex Agent
-- Run: sql/06_create_cortex_agent.sql

-- ============================================================================
-- QUICK START - Run All Scripts in Snowsight
-- ============================================================================
-- Copy and paste each script into Snowsight SQL Worksheet and run in order:
--   1. 01_setup_database.sql
--   2. 02_create_raw_tables.sql
--   3. 03_create_curated_views.sql
--   4. 04_create_semantic_view.sql
--   5. 05_create_cortex_search.sql
--   6. 06_create_cortex_agent.sql
--
-- Or use SnowSQL:
--   snowsql -f 01_setup_database.sql
--   snowsql -f 02_create_raw_tables.sql
--   ... and so on
-- ============================================================================

-- ============================================================================
-- VERIFICATION QUERIES (Run after setup is complete)
-- ============================================================================
USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE STERIS_RELIABILITY_DB;
USE WAREHOUSE STERIS_ANALYTICS_WH;

SELECT '=== STERIS RELIABILITY PLATFORM SETUP VERIFICATION ===' AS STATUS;

-- Verify all objects created
SELECT 'SCHEMA' AS OBJECT_TYPE, SCHEMA_NAME AS NAME 
FROM STERIS_RELIABILITY_DB.INFORMATION_SCHEMA.SCHEMATA 
WHERE SCHEMA_NAME IN ('RAW_DATA', 'CURATED_DATA', 'SEMANTIC_LAYER', 'AI_SERVICES')
ORDER BY SCHEMA_NAME;

-- Data counts
SELECT 
    'Data Verification' AS CHECK_TYPE,
    (SELECT COUNT(*) FROM RAW_DATA.EMAINT_ASSETS) AS ASSETS,
    (SELECT COUNT(*) FROM RAW_DATA.EMAINT_WORK_ORDERS) AS WORK_ORDERS,
    (SELECT COUNT(*) FROM RAW_DATA.TECH_NOTES_UNSTRUCTURED) AS TECH_NOTES,
    (SELECT COUNT(*) FROM RAW_DATA.IGNITION_SCADA_TELEMETRY) AS TELEMETRY,
    (SELECT COUNT(*) FROM RAW_DATA.SEPASOFT_MES_PRODUCTION) AS PRODUCTION;

-- Check Semantic View
SELECT 'Semantic View' AS OBJECT_TYPE, TABLE_NAME AS NAME 
FROM SEMANTIC_LAYER.INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'SEMANTIC VIEW';

-- Check Cortex Search Service
SHOW CORTEX SEARCH SERVICES IN SCHEMA AI_SERVICES;

-- Check Cortex Agent
SHOW AGENTS IN SCHEMA AI_SERVICES;

SELECT '=== SETUP COMPLETE - Ready for Demo! ===' AS STATUS;
