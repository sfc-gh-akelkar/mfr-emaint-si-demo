-- ============================================================================
-- STERIS "Factory of the Future" AI Reliability Platform
-- DEMO QUERIES - For Testing and Demonstration
-- ============================================================================
-- These queries can be used to verify the setup and demonstrate capabilities.
-- ============================================================================

USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE STERIS_RELIABILITY_DB;
USE WAREHOUSE STERIS_ANALYTICS_WH;

-- ============================================================================
-- SECTION 1: DATA VERIFICATION QUERIES
-- ============================================================================

-- Count records in all tables
SELECT 'EMAINT_ASSETS' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM RAW_DATA.EMAINT_ASSETS
UNION ALL SELECT 'EMAINT_WORK_ORDERS', COUNT(*) FROM RAW_DATA.EMAINT_WORK_ORDERS
UNION ALL SELECT 'TECH_NOTES_UNSTRUCTURED', COUNT(*) FROM RAW_DATA.TECH_NOTES_UNSTRUCTURED
UNION ALL SELECT 'IGNITION_SCADA_TELEMETRY', COUNT(*) FROM RAW_DATA.IGNITION_SCADA_TELEMETRY
UNION ALL SELECT 'SEPASOFT_MES_PRODUCTION', COUNT(*) FROM RAW_DATA.SEPASOFT_MES_PRODUCTION;

-- View assets by plant
SELECT PLANT, COUNT(*) AS ASSET_COUNT, AVG(ASSET_HEALTH_SCORE) AS AVG_HEALTH
FROM RAW_DATA.EMAINT_ASSETS
GROUP BY PLANT
ORDER BY PLANT;

-- ============================================================================
-- SECTION 2: CURATED VIEW QUERIES
-- ============================================================================

-- Maintenance summary by plant
SELECT * FROM CURATED_DATA.PLANT_COMPARISON_VW;

-- Assets with low health scores
SELECT ASSET_ID, ASSET_NAME, ASSET_TYPE, PLANT, ASSET_HEALTH_SCORE, TOTAL_MAINTENANCE_COST
FROM CURATED_DATA.ASSET_PERFORMANCE_SUMMARY_VW
WHERE ASSET_HEALTH_SCORE < 80
ORDER BY ASSET_HEALTH_SCORE;

-- Current vibration alerts
SELECT * FROM CURATED_DATA.VIBRATION_ALERT_HISTORY_VW
WHERE ALARM_STATUS IN ('High', 'Critical')
ORDER BY READING_TIMESTAMP DESC
LIMIT 10;

-- OEE summary for packaging equipment
SELECT * FROM CURATED_DATA.PRODUCTION_OEE_SUMMARY_VW
WHERE ASSET_TYPE = 'Packaging System';

-- ============================================================================
-- SECTION 3: SEMANTIC VIEW QUERIES
-- ============================================================================
USE SCHEMA SEMANTIC_LAYER;

-- Total maintenance cost by plant
SELECT * FROM SEMANTIC_VIEW(
    MAINTENANCE_SEMANTIC_VW
    DIMENSIONS assets.plant
    METRICS work_orders.total_maintenance_cost, work_orders.average_mttr
);

-- Work order counts by type and plant
SELECT * FROM SEMANTIC_VIEW(
    MAINTENANCE_SEMANTIC_VW
    DIMENSIONS assets.plant, work_orders.work_order_type
    METRICS work_orders.work_order_count
);

-- Asset health by type
SELECT * FROM SEMANTIC_VIEW(
    MAINTENANCE_SEMANTIC_VW
    DIMENSIONS assets.asset_type
    METRICS assets.asset_count, assets.average_health_score, work_orders.total_downtime
);

-- Top failure codes
SELECT * FROM SEMANTIC_VIEW(
    MAINTENANCE_SEMANTIC_VW
    DIMENSIONS work_orders.failure_code
    METRICS work_orders.work_order_count, work_orders.total_maintenance_cost
)
ORDER BY WORK_ORDER_COUNT DESC
LIMIT 10;

-- ============================================================================
-- SECTION 4: CORTEX SEARCH QUERIES
-- ============================================================================
USE SCHEMA AI_SERVICES;

-- Search for Novus 600 wobbling fix
SELECT
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'STERIS_RELIABILITY_DB.AI_SERVICES.TECH_NOTES_SEARCH_SERVICE',
        '{
            "query": "Novus 600 wobbling fix pneumatic actuator bracket",
            "columns": ["NOTE_ID", "ASSET_ID", "TECHNICIAN", "NOTE_DATE", "NOTE_TEXT"],
            "limit": 5
        }'
    ) AS WOBBLING_FIX_RESULTS;

-- Search for vibration troubleshooting
SELECT
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'STERIS_RELIABILITY_DB.AI_SERVICES.TECH_NOTES_SEARCH_SERVICE',
        '{
            "query": "vibration troubleshooting bearing replacement",
            "columns": ["NOTE_ID", "ASSET_ID", "TECHNICIAN", "NOTE_TEXT"],
            "limit": 5
        }'
    ) AS VIBRATION_TROUBLESHOOTING;

-- Search for steam sterilizer issues
SELECT
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'STERIS_RELIABILITY_DB.AI_SERVICES.TECH_NOTES_SEARCH_SERVICE',
        '{
            "query": "steam sterilizer pressure valve repair",
            "columns": ["NOTE_ID", "ASSET_ID", "TECHNICIAN", "NOTE_TEXT"],
            "limit": 5
        }'
    ) AS STERILIZER_ISSUES;

-- ============================================================================
-- SECTION 5: THE STAR DEMO - NOVUS 600 WOBBLING ISSUE
-- ============================================================================

-- Step 1: Show the current vibration spike
SELECT 
    t.ASSET_ID,
    a.ASSET_NAME,
    a.PLANT,
    t.READING_TIMESTAMP,
    t.READING_VALUE AS VIBRATION_MM_S,
    t.ALARM_STATUS,
    t.ALARM_THRESHOLD
FROM RAW_DATA.IGNITION_SCADA_TELEMETRY t
JOIN RAW_DATA.EMAINT_ASSETS a ON t.ASSET_ID = a.ASSET_ID
WHERE t.ASSET_ID = 'AST-010'
  AND t.SENSOR_TYPE = 'Vibration'
ORDER BY t.READING_TIMESTAMP DESC
LIMIT 10;

-- Step 2: Show the work order history for this asset
SELECT 
    WO_ID,
    WO_TYPE,
    WORK_DESCRIPTION,
    FAILURE_CODE,
    ROOT_CAUSE,
    COMPLETED_DATE,
    TOTAL_REPAIR_COST,
    MTTR_HOURS,
    TECHNICIAN
FROM RAW_DATA.EMAINT_WORK_ORDERS
WHERE ASSET_ID = 'AST-010'
ORDER BY CREATED_DATE DESC;

-- Step 3: Search for the fix in technician notes
SELECT
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'STERIS_RELIABILITY_DB.AI_SERVICES.TECH_NOTES_SEARCH_SERVICE',
        '{
            "query": "wobbling Novus 600 pneumatic actuator bracket realign fix",
            "columns": ["NOTE_ID", "ASSET_ID", "TECHNICIAN", "NOTE_DATE", "NOTE_TEXT"],
            "filter": {"@eq": {"ASSET_ID": "AST-010"}},
            "limit": 10
        }'
    ) AS NOVUS_600_FIX;

-- Step 4: Show production impact
SELECT 
    PRODUCTION_DATE,
    SHIFT,
    UNITS_PRODUCED,
    UNITS_TARGET,
    OEE_OVERALL,
    DOWNTIME_MINUTES,
    DOWNTIME_REASON,
    QUALITY_STATUS
FROM RAW_DATA.SEPASOFT_MES_PRODUCTION
WHERE ASSET_ID = 'AST-010'
ORDER BY PRODUCTION_DATE DESC, SHIFT;

-- ============================================================================
-- SECTION 6: PLANT BENCHMARKING QUERIES
-- ============================================================================

-- Compare key metrics across plants
SELECT 
    PLANT,
    TOTAL_ASSETS,
    AVG_ASSET_HEALTH,
    ROUND(AVG_ASSET_AGE_YEARS, 1) AS AVG_AGE_YEARS,
    TOTAL_WORK_ORDERS,
    ROUND(AVG_MTTR_HOURS, 1) AS AVG_MTTR_HOURS,
    TOTAL_MAINTENANCE_COST,
    ROUND(PREVENTIVE_MAINTENANCE_PCT, 1) AS PM_PCT
FROM CURATED_DATA.PLANT_COMPARISON_VW
ORDER BY PLANT;

-- Show why Hendrix outperforms legacy plants
SELECT 
    a.PLANT,
    a.ASSET_TYPE,
    COUNT(*) AS ASSET_COUNT,
    AVG(a.CURRENT_AGE_YEARS) AS AVG_AGE,
    AVG(a.ASSET_HEALTH_SCORE) AS AVG_HEALTH
FROM RAW_DATA.EMAINT_ASSETS a
GROUP BY a.PLANT, a.ASSET_TYPE
ORDER BY a.PLANT, a.ASSET_TYPE;

-- ============================================================================
-- SECTION 7: COST ANALYSIS
-- ============================================================================

-- Total costs by plant and year
SELECT 
    a.PLANT,
    YEAR(wo.CREATED_DATE) AS WORK_YEAR,
    SUM(wo.TOTAL_REPAIR_COST) AS TOTAL_COST,
    COUNT(wo.WO_ID) AS WO_COUNT,
    AVG(wo.MTTR_HOURS) AS AVG_MTTR
FROM RAW_DATA.EMAINT_WORK_ORDERS wo
JOIN RAW_DATA.EMAINT_ASSETS a ON wo.ASSET_ID = a.ASSET_ID
WHERE wo.STATUS = 'Completed'
GROUP BY a.PLANT, YEAR(wo.CREATED_DATE)
ORDER BY WORK_YEAR, a.PLANT;

-- Most expensive repairs
SELECT 
    wo.WO_ID,
    a.ASSET_NAME,
    a.PLANT,
    wo.WORK_DESCRIPTION,
    wo.TOTAL_REPAIR_COST,
    wo.MTTR_HOURS
FROM RAW_DATA.EMAINT_WORK_ORDERS wo
JOIN RAW_DATA.EMAINT_ASSETS a ON wo.ASSET_ID = a.ASSET_ID
WHERE wo.STATUS = 'Completed'
ORDER BY wo.TOTAL_REPAIR_COST DESC
LIMIT 10;

-- ============================================================================
-- SECTION 8: TECHNICIAN PRODUCTIVITY
-- ============================================================================

-- Work orders by technician
SELECT 
    wo.TECHNICIAN,
    COUNT(wo.WO_ID) AS WO_COUNT,
    SUM(wo.LABOR_HOURS) AS TOTAL_HOURS,
    AVG(wo.MTTR_HOURS) AS AVG_MTTR,
    SUM(wo.TOTAL_REPAIR_COST) AS TOTAL_REPAIR_VALUE
FROM RAW_DATA.EMAINT_WORK_ORDERS wo
WHERE wo.STATUS = 'Completed' AND wo.TECHNICIAN IS NOT NULL
GROUP BY wo.TECHNICIAN
ORDER BY WO_COUNT DESC;

-- ============================================================================
-- END OF DEMO QUERIES
-- ============================================================================

