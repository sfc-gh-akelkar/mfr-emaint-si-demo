-- ============================================================================
-- STERIS "Factory of the Future" AI Reliability Platform
-- Step 1: Database and Schema Setup
-- ============================================================================
-- This script creates the foundational database objects for the STERIS eMaint
-- demo using Snowflake Intelligence capabilities.
-- ============================================================================

USE ROLE SF_INTELLIGENCE_DEMO;

-- Create the database for STERIS reliability platform
CREATE DATABASE IF NOT EXISTS STERIS_RELIABILITY_DB
    COMMENT = 'STERIS Factory of the Future AI Reliability Platform - Hendrix Lighthouse Facility';

USE DATABASE STERIS_RELIABILITY_DB;

-- Create schemas for different data domains
CREATE SCHEMA IF NOT EXISTS RAW_DATA
    COMMENT = 'Raw data ingested from eMaint CMMS, Ignition SCADA, and Sepasoft MES';

CREATE SCHEMA IF NOT EXISTS CURATED_DATA
    COMMENT = 'Curated and joined data for analytics and reporting';

CREATE SCHEMA IF NOT EXISTS SEMANTIC_LAYER
    COMMENT = 'Semantic views for Cortex Analyst natural language queries';

CREATE SCHEMA IF NOT EXISTS AI_SERVICES
    COMMENT = 'Cortex Search services and Agent configurations';

-- Create a warehouse for data processing
CREATE WAREHOUSE IF NOT EXISTS STERIS_ANALYTICS_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'Warehouse for STERIS analytics and AI services';

-- Grant necessary permissions
GRANT USAGE ON DATABASE STERIS_RELIABILITY_DB TO ROLE SF_INTELLIGENCE_DEMO;
GRANT USAGE ON ALL SCHEMAS IN DATABASE STERIS_RELIABILITY_DB TO ROLE SF_INTELLIGENCE_DEMO;
GRANT ALL ON ALL SCHEMAS IN DATABASE STERIS_RELIABILITY_DB TO ROLE SF_INTELLIGENCE_DEMO;
GRANT USAGE ON WAREHOUSE STERIS_ANALYTICS_WH TO ROLE SF_INTELLIGENCE_DEMO;

-- Set context for subsequent operations
USE WAREHOUSE STERIS_ANALYTICS_WH;

SELECT 'Database setup complete for STERIS Reliability Platform' AS STATUS;

