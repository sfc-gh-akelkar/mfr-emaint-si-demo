-- ============================================================================
-- STERIS "Factory of the Future" AI Reliability Platform
-- Step 4: Create Semantic View for Cortex Analyst
-- ============================================================================
-- This script creates a native Snowflake Semantic View that enables
-- Cortex Analyst to understand STERIS-specific maintenance terminology
-- and answer natural language questions about asset reliability.
--
-- REFERENCE: https://docs.snowflake.com/en/user-guide/views-semantic/example
-- ============================================================================

USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE STERIS_RELIABILITY_DB;
USE SCHEMA SEMANTIC_LAYER;
USE WAREHOUSE STERIS_ANALYTICS_WH;

-- ============================================================================
-- Create the MAINTENANCE_SEMANTIC_VW Semantic View
-- ============================================================================
-- This semantic view joins work orders, assets, and production data to enable
-- natural language queries about maintenance costs, MTTR, asset health, and
-- plant-level benchmarking.
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW MAINTENANCE_SEMANTIC_VW

-- ============================================================================
-- TABLES: Define the logical tables and their relationships
-- ============================================================================
TABLES (
    -- Work Orders table from eMaint CMMS
    work_orders AS STERIS_RELIABILITY_DB.RAW_DATA.EMAINT_WORK_ORDERS
        PRIMARY KEY (WO_ID)
        WITH SYNONYMS = ('maintenance orders', 'service tickets', 'repair orders', 'WOs')
        COMMENT = 'Work orders from eMaint CMMS tracking all maintenance activities including corrective repairs and preventive maintenance',
    
    -- Assets table from eMaint CMMS
    assets AS STERIS_RELIABILITY_DB.RAW_DATA.EMAINT_ASSETS
        PRIMARY KEY (ASSET_ID)
        WITH SYNONYMS = ('equipment', 'machines', 'devices', 'units')
        COMMENT = 'STERIS equipment master data including sterilizers, washers, and packaging systems across all plants',
    
    -- Production data from Sepasoft MES
    production AS STERIS_RELIABILITY_DB.RAW_DATA.SEPASOFT_MES_PRODUCTION
        PRIMARY KEY (PRODUCTION_ID)
        WITH SYNONYMS = ('manufacturing data', 'output data', 'OEE data')
        COMMENT = 'Production performance data from Sepasoft MES including OEE metrics and quality status',
    
    -- Telemetry from Ignition SCADA
    telemetry AS STERIS_RELIABILITY_DB.RAW_DATA.IGNITION_SCADA_TELEMETRY
        PRIMARY KEY (TELEMETRY_ID)
        WITH SYNONYMS = ('sensor data', 'SCADA data', 'real-time data', 'readings')
        COMMENT = 'Real-time sensor telemetry from Ignition SCADA including vibration, temperature, and pressure'
)

-- ============================================================================
-- RELATIONSHIPS: Define how tables join together
-- ============================================================================
RELATIONSHIPS (
    -- Work orders reference assets
    work_orders (ASSET_ID) REFERENCES assets (ASSET_ID),
    
    -- Production records reference assets
    production (ASSET_ID) REFERENCES assets (ASSET_ID),
    
    -- Telemetry readings reference assets
    telemetry (ASSET_ID) REFERENCES assets (ASSET_ID)
)

-- ============================================================================
-- FACTS: Additive numeric values used in calculations
-- ============================================================================
FACTS (
    -- Cost Facts
    work_orders.repair_cost AS work_orders.TOTAL_REPAIR_COST
        COMMENT = 'Total cost of repair including parts and labor in USD',
    
    work_orders.parts_cost AS work_orders.PARTS_COST
        COMMENT = 'Cost of replacement parts and materials in USD',
    
    work_orders.labor_cost AS work_orders.LABOR_COST
        COMMENT = 'Cost of technician labor at $75/hour in USD',
    
    -- Time Facts
    work_orders.mttr AS work_orders.MTTR_HOURS
        COMMENT = 'Mean Time To Repair in hours - measures repair efficiency',
    
    work_orders.downtime AS work_orders.DOWNTIME_HOURS
        COMMENT = 'Total equipment downtime in hours including wait and repair time',
    
    work_orders.labor_hours AS work_orders.LABOR_HOURS
        COMMENT = 'Technician labor hours spent on the repair',
    
    -- Production Facts
    production.units_produced AS production.UNITS_PRODUCED
        COMMENT = 'Number of units produced in the production run',
    
    production.units_target AS production.UNITS_TARGET
        COMMENT = 'Target production quantity for the run',
    
    production.units_rejected AS production.UNITS_REJECTED
        COMMENT = 'Number of units rejected for quality issues',
    
    production.downtime_minutes AS production.DOWNTIME_MINUTES
        COMMENT = 'Unplanned downtime during production in minutes',
    
    -- OEE Component Facts
    production.oee_availability AS production.OEE_AVAILABILITY
        COMMENT = 'OEE Availability factor (0-1): Actual run time / Planned production time',
    
    production.oee_performance AS production.OEE_PERFORMANCE
        COMMENT = 'OEE Performance factor (0-1): Actual output / Expected output at full speed',
    
    production.oee_quality AS production.OEE_QUALITY
        COMMENT = 'OEE Quality factor (0-1): Good units / Total units produced',
    
    production.oee_overall AS production.OEE_OVERALL
        COMMENT = 'Overall Equipment Effectiveness (Availability × Performance × Quality) - world-class is above 0.85',
    
    -- Telemetry Facts
    telemetry.sensor_reading AS telemetry.READING_VALUE
        COMMENT = 'Numeric value of the sensor reading (vibration in mm/s, temperature in °F, pressure in PSI)',
    
    telemetry.alarm_threshold AS telemetry.ALARM_THRESHOLD
        COMMENT = 'Configured alarm threshold for the sensor',
    
    -- Asset Facts
    assets.health_score AS assets.ASSET_HEALTH_SCORE
        COMMENT = 'Asset health score from 0-100 based on age, maintenance history, and telemetry. Below 70 indicates concern.',
    
    assets.asset_age AS assets.CURRENT_AGE_YEARS
        COMMENT = 'Current age of the asset in years since installation',
    
    assets.expected_life AS assets.EXPECTED_LIFE_YEARS
        COMMENT = 'Expected useful life of the asset in years'
)

-- ============================================================================
-- DIMENSIONS: Attributes for filtering, grouping, and slicing
-- ============================================================================
DIMENSIONS (
    -- Work Order Dimensions
    work_orders.work_order_id AS work_orders.WO_ID
        WITH SYNONYMS = ('WO number', 'ticket number', 'order number')
        COMMENT = 'Unique work order identifier',
    
    work_orders.work_order_type AS work_orders.WO_TYPE
        WITH SYNONYMS = ('WO type', 'maintenance type', 'order type')
        COMMENT = 'Type of work order: Corrective (breakdown), Preventive (scheduled PM), Emergency, or Investigation',
    
    work_orders.failure_code AS work_orders.FAILURE_CODE
        WITH SYNONYMS = ('fault code', 'error code', 'problem code')
        COMMENT = 'Standardized failure code (STM-FAIL=steam failure, VIB-09=vibration, SEAL-FAIL=seal failure, PUMP-FAIL=pump failure)',
    
    work_orders.root_cause AS work_orders.ROOT_CAUSE
        WITH SYNONYMS = ('cause', 'reason', 'why it failed')
        COMMENT = 'Identified root cause of the failure',
    
    work_orders.priority AS work_orders.PRIORITY
        WITH SYNONYMS = ('urgency', 'importance')
        COMMENT = 'Work priority: Critical, High, Medium, or Low',
    
    work_orders.status AS work_orders.STATUS
        WITH SYNONYMS = ('WO status', 'order status', 'current state')
        COMMENT = 'Work order status: Open, Scheduled, In Progress, Completed, or Cancelled',
    
    work_orders.technician AS work_orders.TECHNICIAN
        WITH SYNONYMS = ('tech', 'mechanic', 'maintenance person', 'worker')
        COMMENT = 'Name of the maintenance technician assigned',
    
    work_orders.created_date AS work_orders.CREATED_DATE
        WITH SYNONYMS = ('order date', 'request date', 'WO date')
        COMMENT = 'Date when the work order was created',
    
    work_orders.completed_date AS work_orders.COMPLETED_DATE
        WITH SYNONYMS = ('finish date', 'close date', 'done date')
        COMMENT = 'Actual completion date of the work',
    
    work_orders.work_year AS YEAR(work_orders.CREATED_DATE)
        WITH SYNONYMS = ('year')
        COMMENT = 'Year the work order was created',
    
    work_orders.work_month AS MONTHNAME(work_orders.CREATED_DATE)
        WITH SYNONYMS = ('month')
        COMMENT = 'Month name the work order was created',
    
    -- Asset Dimensions
    assets.asset_id AS assets.ASSET_ID
        WITH SYNONYMS = ('equipment ID', 'machine ID', 'tag')
        COMMENT = 'Unique identifier for each asset in eMaint system',
    
    assets.asset_name AS assets.ASSET_NAME
        WITH SYNONYMS = ('equipment name', 'machine name', 'unit name')
        COMMENT = 'Human-readable name of the equipment',
    
    assets.asset_type AS assets.ASSET_TYPE
        WITH SYNONYMS = ('equipment type', 'machine type', 'category')
        COMMENT = 'Category: Steam Sterilizer, Washer-Disinfector, Packaging System, Low-Temp Sterilizer, or Utility System',
    
    assets.manufacturer AS assets.MANUFACTURER
        WITH SYNONYMS = ('make', 'brand', 'vendor')
        COMMENT = 'Equipment manufacturer - primarily STERIS for core equipment',
    
    assets.model AS assets.MODEL
        WITH SYNONYMS = ('model number', 'model name')
        COMMENT = 'Specific model (AMSCO Century V116, AMSCO Evolution, Reliance 444, Reliance 600, Novus 600, V-PRO maX)',
    
    assets.plant AS assets.PLANT
        WITH SYNONYMS = ('facility', 'site', 'location')
        COMMENT = 'Facility: Plant A (legacy), Plant B (legacy), or Hendrix (new lighthouse facility)',
    
    assets.location AS assets.LOCATION
        WITH SYNONYMS = ('area', 'department', 'zone')
        COMMENT = 'Physical location within the plant',
    
    assets.asset_status AS assets.ASSET_STATUS
        WITH SYNONYMS = ('equipment status', 'machine status', 'current status')
        COMMENT = 'Current operational status: Operational, Warning, or Down',
    
    assets.criticality AS assets.CRITICALITY
        WITH SYNONYMS = ('importance', 'priority level', 'business impact')
        COMMENT = 'Business criticality: Critical (production stops if down), High, Medium, or Low',
    
    -- Production Dimensions
    production.product_type AS production.PRODUCT_TYPE
        WITH SYNONYMS = ('product', 'output type', 'what was made')
        COMMENT = 'Type of product being produced',
    
    production.shift AS production.SHIFT
        WITH SYNONYMS = ('work shift')
        COMMENT = 'Production shift: Day or Night',
    
    production.quality_status AS production.QUALITY_STATUS
        WITH SYNONYMS = ('quality rating', 'quality level')
        COMMENT = 'Overall quality rating: Excellent, Good, Acceptable, or Poor',
    
    production.production_date AS production.PRODUCTION_DATE
        WITH SYNONYMS = ('production day', 'run date')
        COMMENT = 'Date of production',
    
    -- Telemetry Dimensions
    telemetry.sensor_type AS telemetry.SENSOR_TYPE
        WITH SYNONYMS = ('measurement type', 'reading type')
        COMMENT = 'Type of sensor: Vibration, Temperature, Pressure, Vacuum, H2O2_Concentration, Dewpoint, or Efficiency',
    
    telemetry.alarm_status AS telemetry.ALARM_STATUS
        WITH SYNONYMS = ('alert status', 'alarm level', 'severity')
        COMMENT = 'Current alarm state: Normal, Warning, High, or Critical',
    
    telemetry.reading_timestamp AS telemetry.READING_TIMESTAMP
        WITH SYNONYMS = ('reading time', 'measurement time', 'when')
        COMMENT = 'Timestamp of the sensor reading'
)

-- ============================================================================
-- METRICS: Calculated aggregations for common business questions
-- ============================================================================
METRICS (
    -- Maintenance Cost Metrics
    work_orders.total_maintenance_cost AS SUM(work_orders.repair_cost)
        WITH SYNONYMS = ('total repair cost', 'maintenance spend', 'repair expenses')
        COMMENT = 'Total maintenance cost across all work orders in USD',
    
    work_orders.average_repair_cost AS AVG(work_orders.repair_cost)
        WITH SYNONYMS = ('avg repair cost', 'mean repair cost', 'typical repair cost')
        COMMENT = 'Average cost per repair in USD',
    
    work_orders.total_parts_cost AS SUM(work_orders.parts_cost)
        WITH SYNONYMS = ('parts spend', 'materials cost')
        COMMENT = 'Total cost of replacement parts in USD',
    
    work_orders.total_labor_cost AS SUM(work_orders.labor_cost)
        WITH SYNONYMS = ('labor spend', 'technician cost')
        COMMENT = 'Total labor cost in USD',
    
    -- Time Metrics (MTTR is critical for reliability)
    work_orders.average_mttr AS AVG(work_orders.mttr)
        WITH SYNONYMS = ('avg MTTR', 'mean time to repair', 'average repair time')
        COMMENT = 'Average Mean Time To Repair in hours - key reliability KPI, lower is better',
    
    work_orders.total_downtime AS SUM(work_orders.downtime)
        WITH SYNONYMS = ('total downtime hours', 'lost production time')
        COMMENT = 'Total equipment downtime in hours across all work orders',
    
    work_orders.average_downtime AS AVG(work_orders.downtime)
        WITH SYNONYMS = ('avg downtime', 'typical downtime')
        COMMENT = 'Average downtime per incident in hours',
    
    work_orders.total_labor_hours AS SUM(work_orders.labor_hours)
        WITH SYNONYMS = ('total tech hours', 'maintenance hours')
        COMMENT = 'Total technician labor hours',
    
    -- Work Order Count Metrics
    work_orders.work_order_count AS COUNT(work_orders.work_order_id)
        WITH SYNONYMS = ('WO count', 'number of work orders', 'maintenance events')
        COMMENT = 'Total count of work orders',
    
    work_orders.corrective_wo_count AS COUNT_IF(work_orders.work_order_type = 'Corrective')
        WITH SYNONYMS = ('breakdown count', 'unplanned repairs')
        COMMENT = 'Count of corrective (breakdown) work orders',
    
    work_orders.preventive_wo_count AS COUNT_IF(work_orders.work_order_type = 'Preventive')
        WITH SYNONYMS = ('PM count', 'scheduled maintenance count')
        COMMENT = 'Count of preventive maintenance work orders',
    
    -- Production Metrics
    production.total_production AS SUM(production.units_produced)
        WITH SYNONYMS = ('total output', 'units made', 'production volume')
        COMMENT = 'Total units produced',
    
    production.total_rejected AS SUM(production.units_rejected)
        WITH SYNONYMS = ('rejects', 'defects', 'bad units')
        COMMENT = 'Total units rejected for quality issues',
    
    production.average_oee AS AVG(production.oee_overall)
        WITH SYNONYMS = ('avg OEE', 'overall equipment effectiveness', 'equipment efficiency')
        COMMENT = 'Average OEE score (0-1). World-class is above 0.85, typical is 0.60-0.70',
    
    -- Asset Metrics
    assets.asset_count AS COUNT(DISTINCT assets.asset_id)
        WITH SYNONYMS = ('equipment count', 'number of machines', 'fleet size')
        COMMENT = 'Count of unique assets',
    
    assets.average_health_score AS AVG(assets.health_score)
        WITH SYNONYMS = ('avg health', 'fleet health', 'equipment condition')
        COMMENT = 'Average asset health score. Below 70 indicates maintenance concerns.',
    
    assets.average_asset_age AS AVG(assets.asset_age)
        WITH SYNONYMS = ('avg age', 'fleet age')
        COMMENT = 'Average age of assets in years'
)

COMMENT = 'STERIS Maintenance Semantic View for Cortex Analyst. Enables natural language queries about maintenance costs, MTTR, asset health, OEE, and plant benchmarking. Use for comparing Hendrix Lighthouse against legacy Plant A and Plant B.';

-- ============================================================================
-- Verify the semantic view was created
-- ============================================================================
DESCRIBE SEMANTIC VIEW MAINTENANCE_SEMANTIC_VW;

-- ============================================================================
-- Example queries to test with Cortex Analyst
-- ============================================================================
/*
Example natural language questions this semantic view supports:

1. "What is the total maintenance cost by plant?"
2. "Show me the average MTTR for critical assets"
3. "Compare the OEE between Hendrix and Plant A"
4. "Which assets have the lowest health scores?"
5. "What are the most common failure codes?"
6. "How many work orders were corrective vs preventive last year?"
7. "What is the total downtime for Novus 600 machines?"
8. "Show repair costs by technician"
9. "Which plant has the best preventive maintenance ratio?"
10. "What's the average repair cost for steam sterilizers?"

Test the semantic view with:
*/

-- Test query using SEMANTIC_VIEW function
SELECT * FROM SEMANTIC_VIEW(
    MAINTENANCE_SEMANTIC_VW
    DIMENSIONS assets.plant
    METRICS work_orders.total_maintenance_cost, work_orders.average_mttr
);

-- Compare plants
SELECT * FROM SEMANTIC_VIEW(
    MAINTENANCE_SEMANTIC_VW
    DIMENSIONS assets.plant
    METRICS assets.asset_count, assets.average_health_score, work_orders.work_order_count
);

