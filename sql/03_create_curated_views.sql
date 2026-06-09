-- ============================================================================
-- MFR "Factory of the Future" AI Reliability Platform
-- Step 3: Create Curated Data Views
-- ============================================================================
-- This script creates joined views that combine data from multiple sources
-- for use by the Semantic Layer.
-- ============================================================================

USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE MFR_RELIABILITY_DB;
USE SCHEMA CURATED_DATA;
USE WAREHOUSE MFR_ANALYTICS_WH;

-- ============================================================================
-- View 1: Maintenance Analytics View
-- Joins Work Orders with Assets for comprehensive maintenance analysis
-- ============================================================================
CREATE OR REPLACE VIEW MAINTENANCE_ANALYTICS_VW AS
SELECT 
    -- Work Order Information
    wo.WO_ID,
    wo.WO_TYPE,
    wo.WORK_DESCRIPTION,
    wo.FAILURE_CODE,
    wo.ROOT_CAUSE,
    wo.PRIORITY,
    wo.STATUS AS WO_STATUS,
    wo.CREATED_DATE,
    wo.SCHEDULED_DATE,
    wo.COMPLETED_DATE,
    wo.TECHNICIAN,
    wo.LABOR_HOURS,
    wo.PARTS_COST,
    wo.LABOR_COST,
    wo.TOTAL_REPAIR_COST,
    wo.MTTR_HOURS,
    wo.DOWNTIME_HOURS,
    
    -- Asset Information
    a.ASSET_ID,
    a.ASSET_NAME,
    a.ASSET_TYPE,
    a.MANUFACTURER,
    a.MODEL,
    a.LOCATION,
    a.PLANT,
    a.INSTALLATION_DATE,
    a.LAST_MAINTENANCE_DATE,
    a.ASSET_STATUS,
    a.CRITICALITY,
    a.EXPECTED_LIFE_YEARS,
    a.CURRENT_AGE_YEARS,
    a.ASSET_HEALTH_SCORE,
    
    -- Calculated Fields
    DATEDIFF('day', wo.CREATED_DATE, wo.COMPLETED_DATE) AS DAYS_TO_COMPLETE,
    CASE 
        WHEN wo.WO_TYPE = 'Corrective' THEN 'Unplanned'
        WHEN wo.WO_TYPE = 'Emergency' THEN 'Unplanned'
        ELSE 'Planned'
    END AS MAINTENANCE_CATEGORY,
    YEAR(wo.CREATED_DATE) AS WO_YEAR,
    QUARTER(wo.CREATED_DATE) AS WO_QUARTER,
    MONTHNAME(wo.CREATED_DATE) AS WO_MONTH
    
FROM RAW_DATA.EMAINT_WORK_ORDERS wo
LEFT JOIN RAW_DATA.EMAINT_ASSETS a ON wo.ASSET_ID = a.ASSET_ID;

COMMENT ON VIEW MAINTENANCE_ANALYTICS_VW IS 
'Joined view of work orders and assets for maintenance analytics. Includes MTTR, costs, and asset health metrics.';

-- ============================================================================
-- View 2: Asset Performance Summary
-- Aggregates maintenance metrics by asset
-- ============================================================================
CREATE OR REPLACE VIEW ASSET_PERFORMANCE_SUMMARY_VW AS
SELECT 
    a.ASSET_ID,
    a.ASSET_NAME,
    a.ASSET_TYPE,
    a.MODEL,
    a.PLANT,
    a.LOCATION,
    a.CRITICALITY,
    a.ASSET_STATUS,
    a.ASSET_HEALTH_SCORE,
    a.CURRENT_AGE_YEARS,
    a.EXPECTED_LIFE_YEARS,
    
    -- Maintenance Metrics
    COUNT(wo.WO_ID) AS TOTAL_WORK_ORDERS,
    SUM(CASE WHEN wo.WO_TYPE = 'Corrective' THEN 1 ELSE 0 END) AS CORRECTIVE_WO_COUNT,
    SUM(CASE WHEN wo.WO_TYPE = 'Preventive' THEN 1 ELSE 0 END) AS PREVENTIVE_WO_COUNT,
    SUM(CASE WHEN wo.WO_TYPE = 'Emergency' THEN 1 ELSE 0 END) AS EMERGENCY_WO_COUNT,
    
    -- Cost Metrics
    SUM(wo.TOTAL_REPAIR_COST) AS TOTAL_MAINTENANCE_COST,
    AVG(wo.TOTAL_REPAIR_COST) AS AVG_REPAIR_COST,
    SUM(wo.PARTS_COST) AS TOTAL_PARTS_COST,
    SUM(wo.LABOR_COST) AS TOTAL_LABOR_COST,
    
    -- Time Metrics
    AVG(wo.MTTR_HOURS) AS AVG_MTTR_HOURS,
    SUM(wo.DOWNTIME_HOURS) AS TOTAL_DOWNTIME_HOURS,
    AVG(wo.LABOR_HOURS) AS AVG_LABOR_HOURS,
    
    -- Reliability Indicators
    ROUND(SUM(CASE WHEN wo.WO_TYPE IN ('Corrective', 'Emergency') THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(COUNT(wo.WO_ID), 0), 2) AS UNPLANNED_MAINTENANCE_PCT

FROM RAW_DATA.EMAINT_ASSETS a
LEFT JOIN RAW_DATA.EMAINT_WORK_ORDERS wo ON a.ASSET_ID = wo.ASSET_ID
GROUP BY 
    a.ASSET_ID, a.ASSET_NAME, a.ASSET_TYPE, a.MODEL, a.PLANT, a.LOCATION,
    a.CRITICALITY, a.ASSET_STATUS, a.ASSET_HEALTH_SCORE, 
    a.CURRENT_AGE_YEARS, a.EXPECTED_LIFE_YEARS;

COMMENT ON VIEW ASSET_PERFORMANCE_SUMMARY_VW IS 
'Summary of maintenance performance metrics by asset including costs, MTTR, and reliability indicators.';

-- ============================================================================
-- View 3: Plant Comparison View
-- Aggregates metrics by plant for benchmarking Hendrix vs legacy facilities
-- ============================================================================
CREATE OR REPLACE VIEW PLANT_COMPARISON_VW AS
SELECT 
    a.PLANT,
    
    -- Asset Counts
    COUNT(DISTINCT a.ASSET_ID) AS TOTAL_ASSETS,
    SUM(CASE WHEN a.ASSET_STATUS = 'Operational' THEN 1 ELSE 0 END) AS OPERATIONAL_ASSETS,
    SUM(CASE WHEN a.ASSET_STATUS = 'Warning' THEN 1 ELSE 0 END) AS WARNING_ASSETS,
    SUM(CASE WHEN a.ASSET_STATUS = 'Down' THEN 1 ELSE 0 END) AS DOWN_ASSETS,
    
    -- Health Metrics
    AVG(a.ASSET_HEALTH_SCORE) AS AVG_ASSET_HEALTH,
    AVG(a.CURRENT_AGE_YEARS) AS AVG_ASSET_AGE_YEARS,
    
    -- Work Order Metrics
    COUNT(wo.WO_ID) AS TOTAL_WORK_ORDERS,
    SUM(CASE WHEN wo.WO_TYPE = 'Corrective' THEN 1 ELSE 0 END) AS CORRECTIVE_WOS,
    SUM(CASE WHEN wo.WO_TYPE = 'Preventive' THEN 1 ELSE 0 END) AS PREVENTIVE_WOS,
    
    -- Cost Metrics
    SUM(wo.TOTAL_REPAIR_COST) AS TOTAL_MAINTENANCE_COST,
    AVG(wo.TOTAL_REPAIR_COST) AS AVG_REPAIR_COST,
    
    -- Time Metrics
    AVG(wo.MTTR_HOURS) AS AVG_MTTR_HOURS,
    SUM(wo.DOWNTIME_HOURS) AS TOTAL_DOWNTIME_HOURS,
    
    -- Reliability Ratio (Preventive / Total)
    ROUND(SUM(CASE WHEN wo.WO_TYPE = 'Preventive' THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(COUNT(wo.WO_ID), 0), 2) AS PREVENTIVE_MAINTENANCE_PCT

FROM RAW_DATA.EMAINT_ASSETS a
LEFT JOIN RAW_DATA.EMAINT_WORK_ORDERS wo ON a.ASSET_ID = wo.ASSET_ID
GROUP BY a.PLANT
ORDER BY a.PLANT;

COMMENT ON VIEW PLANT_COMPARISON_VW IS 
'Plant-level aggregation for benchmarking primary manufacturing facility against legacy Plant A and Plant B facilities.';

-- ============================================================================
-- View 4: Current Asset Telemetry Status
-- Latest sensor readings for each asset
-- ============================================================================
CREATE OR REPLACE VIEW CURRENT_ASSET_TELEMETRY_VW AS
WITH LatestReadings AS (
    SELECT 
        t.*,
        ROW_NUMBER() OVER (PARTITION BY t.ASSET_ID, t.SENSOR_TYPE ORDER BY t.READING_TIMESTAMP DESC) AS RN
    FROM RAW_DATA.IGNITION_SCADA_TELEMETRY t
)
SELECT 
    a.ASSET_ID,
    a.ASSET_NAME,
    a.ASSET_TYPE,
    a.PLANT,
    a.ASSET_STATUS,
    a.ASSET_HEALTH_SCORE,
    lr.SENSOR_TYPE,
    lr.SENSOR_NAME,
    lr.READING_TIMESTAMP AS LATEST_READING_TIME,
    lr.READING_VALUE,
    lr.UNIT,
    lr.ALARM_STATUS,
    lr.ALARM_THRESHOLD,
    CASE 
        WHEN lr.READING_VALUE >= lr.ALARM_THRESHOLD THEN 'EXCEEDED'
        WHEN lr.READING_VALUE >= lr.ALARM_THRESHOLD * 0.8 THEN 'APPROACHING'
        ELSE 'NORMAL'
    END AS THRESHOLD_STATUS
FROM LatestReadings lr
JOIN RAW_DATA.EMAINT_ASSETS a ON lr.ASSET_ID = a.ASSET_ID
WHERE lr.RN = 1;

COMMENT ON VIEW CURRENT_ASSET_TELEMETRY_VW IS 
'Latest sensor readings for each asset from Ignition SCADA, useful for current status and alarm monitoring.';

-- ============================================================================
-- View 5: Production OEE Summary
-- Production performance aggregated by asset
-- ============================================================================
CREATE OR REPLACE VIEW PRODUCTION_OEE_SUMMARY_VW AS
SELECT 
    a.ASSET_ID,
    a.ASSET_NAME,
    a.ASSET_TYPE,
    a.PLANT,
    p.PRODUCT_TYPE,
    
    -- Production Metrics
    COUNT(p.PRODUCTION_ID) AS TOTAL_PRODUCTION_RUNS,
    SUM(p.UNITS_PRODUCED) AS TOTAL_UNITS_PRODUCED,
    SUM(p.UNITS_TARGET) AS TOTAL_UNITS_TARGET,
    SUM(p.UNITS_REJECTED) AS TOTAL_UNITS_REJECTED,
    
    -- OEE Metrics
    AVG(p.OEE_AVAILABILITY) AS AVG_AVAILABILITY,
    AVG(p.OEE_PERFORMANCE) AS AVG_PERFORMANCE,
    AVG(p.OEE_QUALITY) AS AVG_QUALITY,
    AVG(p.OEE_OVERALL) AS AVG_OEE_OVERALL,
    
    -- Downtime
    SUM(p.DOWNTIME_MINUTES) AS TOTAL_DOWNTIME_MINUTES,
    
    -- Quality Distribution
    SUM(CASE WHEN p.QUALITY_STATUS = 'Excellent' THEN 1 ELSE 0 END) AS EXCELLENT_COUNT,
    SUM(CASE WHEN p.QUALITY_STATUS = 'Good' THEN 1 ELSE 0 END) AS GOOD_COUNT,
    SUM(CASE WHEN p.QUALITY_STATUS = 'Acceptable' THEN 1 ELSE 0 END) AS ACCEPTABLE_COUNT,
    SUM(CASE WHEN p.QUALITY_STATUS = 'Poor' THEN 1 ELSE 0 END) AS POOR_COUNT

FROM RAW_DATA.EMAINT_ASSETS a
JOIN RAW_DATA.SEPASOFT_MES_PRODUCTION p ON a.ASSET_ID = p.ASSET_ID
GROUP BY a.ASSET_ID, a.ASSET_NAME, a.ASSET_TYPE, a.PLANT, p.PRODUCT_TYPE;

COMMENT ON VIEW PRODUCTION_OEE_SUMMARY_VW IS 
'Production performance summary from Sepasoft MES including OEE metrics and quality distribution by asset.';

-- ============================================================================
-- View 6: Vibration Alert History (for Novus 600 analysis)
-- ============================================================================
CREATE OR REPLACE VIEW VIBRATION_ALERT_HISTORY_VW AS
SELECT 
    t.TELEMETRY_ID,
    t.ASSET_ID,
    a.ASSET_NAME,
    a.PLANT,
    t.READING_TIMESTAMP,
    t.READING_VALUE AS VIBRATION_MM_S,
    t.ALARM_STATUS,
    t.ALARM_THRESHOLD,
    CASE 
        WHEN t.ALARM_STATUS = 'Critical' THEN 'IMMEDIATE ACTION REQUIRED'
        WHEN t.ALARM_STATUS = 'High' THEN 'SCHEDULE INSPECTION'
        WHEN t.ALARM_STATUS = 'Warning' THEN 'MONITOR CLOSELY'
        ELSE 'NORMAL OPERATION'
    END AS RECOMMENDED_ACTION
FROM RAW_DATA.IGNITION_SCADA_TELEMETRY t
JOIN RAW_DATA.EMAINT_ASSETS a ON t.ASSET_ID = a.ASSET_ID
WHERE t.SENSOR_TYPE = 'Vibration'
ORDER BY t.READING_TIMESTAMP DESC;

COMMENT ON VIEW VIBRATION_ALERT_HISTORY_VW IS 
'Historical vibration readings and alerts, especially useful for Novus 600 wobbling issue analysis.';

-- Verify views created
SELECT TABLE_NAME, TABLE_TYPE, COMMENT 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'CURATED_DATA' 
ORDER BY TABLE_NAME;

