-- ============================================================================
-- STERIS "Factory of the Future" AI Reliability Platform
-- Step 5: Create Cortex Search Service for Technician Notes
-- ============================================================================
-- This script creates a Cortex Search service on the unstructured technician
-- notes, enabling semantic search for troubleshooting information and
-- tribal knowledge captured in maintenance logbooks.
-- ============================================================================

USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE STERIS_RELIABILITY_DB;
USE SCHEMA AI_SERVICES;
USE WAREHOUSE STERIS_ANALYTICS_WH;

-- ============================================================================
-- Create the Cortex Search Service for Tech Notes
-- ============================================================================
-- This service enables semantic search over technician notes, allowing
-- natural language queries like "How do I fix wobbling on Novus 600?"
-- ============================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE TECH_NOTES_SEARCH_SERVICE
    ON NOTE_TEXT                           -- Primary text column to search
    ATTRIBUTES ASSET_ID, TECHNICIAN        -- Columns available for filtering
    WAREHOUSE = STERIS_ANALYTICS_WH
    TARGET_LAG = '1 hour'                  -- Refresh frequency
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    COMMENT = 'Semantic search service for technician logbook entries. Use to find troubleshooting tips, repair procedures, and tribal knowledge.'
    AS (
        SELECT 
            NOTE_ID,
            ASSET_ID,
            WO_ID,
            TECHNICIAN,
            NOTE_DATE,
            NOTE_TEXT,
            -- Add context to improve search quality
            CONCAT(
                'Asset: ', COALESCE(ASSET_ID, 'Unknown'),
                ' | Date: ', TO_VARCHAR(NOTE_DATE, 'YYYY-MM-DD'),
                ' | Technician: ', COALESCE(TECHNICIAN, 'Unknown'),
                ' | Note: ', NOTE_TEXT
            ) AS ENRICHED_NOTE
        FROM RAW_DATA.TECH_NOTES_UNSTRUCTURED
    );

-- ============================================================================
-- Describe the search service
-- ============================================================================
DESCRIBE CORTEX SEARCH SERVICE TECH_NOTES_SEARCH_SERVICE;

-- ============================================================================
-- Test the Cortex Search Service
-- ============================================================================
-- Use the modern SEARCH_PREVIEW function for testing

-- Test 1: Search for Novus 600 wobbling fix
SELECT
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'STERIS_RELIABILITY_DB.AI_SERVICES.TECH_NOTES_SEARCH_SERVICE',
        '{
            "query": "How to fix wobbling issue on Novus 600 packaging machine?",
            "columns": ["NOTE_ID", "ASSET_ID", "TECHNICIAN", "NOTE_DATE", "NOTE_TEXT"],
            "limit": 5
        }'
    ) AS SEARCH_RESULTS;

-- Test 2: Search for bearing replacement procedures
SELECT
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'STERIS_RELIABILITY_DB.AI_SERVICES.TECH_NOTES_SEARCH_SERVICE',
        '{
            "query": "bearing replacement procedure and tips",
            "columns": ["NOTE_ID", "ASSET_ID", "TECHNICIAN", "NOTE_TEXT"],
            "limit": 5
        }'
    ) AS SEARCH_RESULTS;

-- Test 3: Search with filter for specific asset
SELECT
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'STERIS_RELIABILITY_DB.AI_SERVICES.TECH_NOTES_SEARCH_SERVICE',
        '{
            "query": "vibration troubleshooting",
            "columns": ["NOTE_ID", "ASSET_ID", "TECHNICIAN", "NOTE_TEXT"],
            "filter": {"@eq": {"ASSET_ID": "AST-010"}},
            "limit": 5
        }'
    ) AS SEARCH_RESULTS;

-- Test 4: Search for steam sterilizer maintenance
SELECT
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'STERIS_RELIABILITY_DB.AI_SERVICES.TECH_NOTES_SEARCH_SERVICE',
        '{
            "query": "steam sterilizer valve pressure issues",
            "columns": ["NOTE_ID", "ASSET_ID", "TECHNICIAN", "NOTE_TEXT"],
            "limit": 5
        }'
    ) AS SEARCH_RESULTS;

-- Test 5: Search by technician
SELECT
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'STERIS_RELIABILITY_DB.AI_SERVICES.TECH_NOTES_SEARCH_SERVICE',
        '{
            "query": "pneumatic actuator bracket alignment",
            "columns": ["NOTE_ID", "ASSET_ID", "TECHNICIAN", "NOTE_TEXT"],
            "filter": {"@eq": {"TECHNICIAN": "Luis Garcia"}},
            "limit": 5
        }'
    ) AS SEARCH_RESULTS;

-- ============================================================================
-- Grant access to the search service
-- ============================================================================
GRANT USAGE ON CORTEX SEARCH SERVICE TECH_NOTES_SEARCH_SERVICE TO ROLE SF_INTELLIGENCE_DEMO;

SELECT 'Cortex Search Service created successfully' AS STATUS;

