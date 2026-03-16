/*******************************************************************************
 * STERIS FACTORY OF THE FUTURE - PREDICTIVE MAINTENANCE
 * Infrastructure Setup Script
 * 
 * Purpose: Create medallion architecture (5 schemas) for ML pipeline
 * Database: STERIS_RELIABILITY_DB
 * 
 * Adapted from Snowflake's AI-Powered Predictive Grid Maintenance demo
 * for medical device manufacturing context
 ******************************************************************************/

USE ROLE SF_INTELLIGENCE_DEMO;
USE WAREHOUSE STERIS_ANALYTICS_WH;

-- =============================================================================
-- SECTION 1: DATABASE SETUP
-- =============================================================================

CREATE DATABASE IF NOT EXISTS STERIS_RELIABILITY_DB
    COMMENT = 'STERIS Factory of the Future - Predictive Maintenance AI System';

USE DATABASE STERIS_RELIABILITY_DB;

-- =============================================================================
-- SECTION 2: MEDALLION ARCHITECTURE SCHEMAS
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS RAW
    COMMENT = 'Bronze layer - Raw data from eMaint CMMS, Ignition SCADA, Sepasoft MES';

CREATE SCHEMA IF NOT EXISTS FEATURES
    COMMENT = 'Silver layer - Engineered features for ML models';

CREATE SCHEMA IF NOT EXISTS ML
    COMMENT = 'ML artifacts - models, predictions, training data';

CREATE SCHEMA IF NOT EXISTS ANALYTICS
    COMMENT = 'Gold layer - Business analytics, KPIs, semantic models';

CREATE SCHEMA IF NOT EXISTS UNSTRUCTURED
    COMMENT = 'Unstructured data - tech notes, maintenance logs, manuals';

CREATE SCHEMA IF NOT EXISTS STAGING
    COMMENT = 'Temporary staging area for data ingestion';

-- =============================================================================
-- SECTION 3: RAW SCHEMA TABLES
-- =============================================================================

USE SCHEMA RAW;

-- Asset Master (from eMaint CMMS)
CREATE OR REPLACE TABLE ASSET_MASTER (
    ASSET_ID VARCHAR(50) PRIMARY KEY,
    ASSET_NAME VARCHAR(200) NOT NULL,
    ASSET_TYPE VARCHAR(50) NOT NULL,
    ASSET_SUBTYPE VARCHAR(50),
    MANUFACTURER VARCHAR(100),
    MODEL VARCHAR(100),
    SERIAL_NUMBER VARCHAR(100),
    INSTALL_DATE DATE,
    EXPECTED_LIFE_YEARS NUMBER(3),
    LOCATION_PLANT VARCHAR(100),
    LOCATION_LINE VARCHAR(100),
    LOCATION_AREA VARCHAR(100),
    CRITICALITY_SCORE NUMBER(3),
    PRODUCTION_IMPACT_HOURLY_USD NUMBER(12,2),
    REPLACEMENT_COST_USD NUMBER(12,2),
    LAST_MAINTENANCE_DATE DATE,
    STATUS VARCHAR(20) DEFAULT 'ACTIVE',
    CREATED_TS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_TS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    METADATA VARIANT
)
COMMENT = 'Master inventory of production equipment from eMaint CMMS'
CLUSTER BY (ASSET_TYPE, STATUS);

-- Sensor Readings (from Ignition SCADA)
CREATE OR REPLACE TABLE SENSOR_READINGS (
    READING_ID NUMBER(38,0) AUTOINCREMENT PRIMARY KEY,
    ASSET_ID VARCHAR(50) NOT NULL,
    READING_TIMESTAMP TIMESTAMP_NTZ NOT NULL,
    
    -- Vibration Measurements
    VIBRATION_MM_S NUMBER(8,4),
    VIBRATION_PEAK_MM_S NUMBER(8,4),
    VIBRATION_RMS NUMBER(8,4),
    
    -- Motor/Electrical Measurements
    MOTOR_CURRENT_A NUMBER(10,2),
    MOTOR_VOLTAGE_V NUMBER(10,2),
    MOTOR_TEMP_C NUMBER(5,2),
    POWER_FACTOR NUMBER(5,4),
    
    -- Process Measurements
    CYCLE_PRESSURE_PSI NUMBER(10,2),
    CYCLE_TEMP_C NUMBER(5,2),
    AMBIENT_TEMP_C NUMBER(5,2),
    HUMIDITY_PCT NUMBER(5,2),
    
    -- Operational
    CYCLE_COUNT NUMBER(10),
    CYCLE_TIME_SEC NUMBER(10,2),
    SPEED_RPM NUMBER(10,2),
    
    -- Metadata
    INGESTION_TS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    CONSTRAINT FK_SENSOR_ASSET FOREIGN KEY (ASSET_ID) REFERENCES ASSET_MASTER(ASSET_ID)
)
COMMENT = 'Time-series sensor data from Ignition SCADA'
CLUSTER BY (READING_TIMESTAMP, ASSET_ID);

-- Work Orders (from eMaint CMMS)
CREATE OR REPLACE TABLE WORK_ORDERS (
    WORK_ORDER_ID VARCHAR(50) PRIMARY KEY,
    ASSET_ID VARCHAR(50) NOT NULL,
    WORK_ORDER_DATE DATE NOT NULL,
    WORK_ORDER_TYPE VARCHAR(50) NOT NULL,
    PRIORITY VARCHAR(20),
    DESCRIPTION VARCHAR(5000),
    TECHNICIAN VARCHAR(100),
    LABOR_HOURS NUMBER(5,2),
    PARTS_COST_USD NUMBER(12,2),
    LABOR_COST_USD NUMBER(12,2),
    TOTAL_COST_USD NUMBER(12,2),
    DOWNTIME_HOURS NUMBER(5,2),
    OUTCOME VARCHAR(50),
    ROOT_CAUSE VARCHAR(500),
    FAILURE_MODE VARCHAR(100),
    PARTS_REPLACED VARIANT,
    CREATED_TS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    CONSTRAINT FK_WO_ASSET FOREIGN KEY (ASSET_ID) REFERENCES ASSET_MASTER(ASSET_ID)
)
COMMENT = 'Work orders and maintenance history from eMaint CMMS'
CLUSTER BY (WORK_ORDER_DATE, ASSET_ID);

-- Failure Events (labeled failures for ML training)
CREATE OR REPLACE TABLE FAILURE_EVENTS (
    EVENT_ID VARCHAR(50) PRIMARY KEY,
    ASSET_ID VARCHAR(50) NOT NULL,
    FAILURE_TIMESTAMP TIMESTAMP_NTZ NOT NULL,
    FAILURE_TYPE VARCHAR(100) NOT NULL,
    ROOT_CAUSE VARCHAR(500),
    DOWNTIME_HOURS NUMBER(5,2),
    REPAIR_COST_USD NUMBER(12,2),
    PRODUCTION_LOSS_USD NUMBER(12,2),
    PREVENTABLE_FLAG BOOLEAN,
    ADVANCED_WARNING_DAYS NUMBER(5),
    WORK_ORDER_ID VARCHAR(50),
    CREATED_TS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    CONSTRAINT FK_FAILURE_ASSET FOREIGN KEY (ASSET_ID) REFERENCES ASSET_MASTER(ASSET_ID)
)
COMMENT = 'Historical failure incidents for ML model training'
CLUSTER BY (FAILURE_TIMESTAMP);

-- Production Data (from Sepasoft MES)
CREATE OR REPLACE TABLE PRODUCTION_RUNS (
    RUN_ID VARCHAR(50) PRIMARY KEY,
    ASSET_ID VARCHAR(50) NOT NULL,
    RUN_DATE DATE NOT NULL,
    SHIFT VARCHAR(20),
    PLANNED_CYCLES NUMBER(10),
    ACTUAL_CYCLES NUMBER(10),
    GOOD_CYCLES NUMBER(10),
    REJECT_CYCLES NUMBER(10),
    PLANNED_RUNTIME_MIN NUMBER(10,2),
    ACTUAL_RUNTIME_MIN NUMBER(10,2),
    DOWNTIME_MIN NUMBER(10,2),
    OEE_AVAILABILITY NUMBER(5,4),
    OEE_PERFORMANCE NUMBER(5,4),
    OEE_QUALITY NUMBER(5,4),
    OEE_OVERALL NUMBER(5,4),
    CREATED_TS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    CONSTRAINT FK_PROD_ASSET FOREIGN KEY (ASSET_ID) REFERENCES ASSET_MASTER(ASSET_ID)
)
COMMENT = 'Production run data from Sepasoft MES'
CLUSTER BY (RUN_DATE, ASSET_ID);

-- =============================================================================
-- SECTION 4: ML SCHEMA TABLES
-- =============================================================================

USE SCHEMA ML;

-- Training Data
CREATE OR REPLACE TABLE TRAINING_DATA (
    RECORD_ID NUMBER(38,0) AUTOINCREMENT PRIMARY KEY,
    ASSET_ID VARCHAR(50) NOT NULL,
    SNAPSHOT_DATE DATE NOT NULL,
    
    -- Target Labels
    FAILURE_WITHIN_30_DAYS BOOLEAN NOT NULL,
    FAILURE_WITHIN_14_DAYS BOOLEAN,
    FAILURE_WITHIN_7_DAYS BOOLEAN,
    DAYS_TO_FAILURE NUMBER(10),
    FAILURE_TYPE VARCHAR(100),
    
    -- Features (stored as VARIANT for flexibility)
    FEATURES VARIANT NOT NULL,
    
    -- Metadata
    TRAINING_SET VARCHAR(20),
    CREATED_TS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Labeled training data for supervised learning models'
CLUSTER BY (SNAPSHOT_DATE, ASSET_ID);

-- Model Registry
CREATE OR REPLACE TABLE MODEL_REGISTRY (
    MODEL_ID VARCHAR(50) PRIMARY KEY,
    MODEL_NAME VARCHAR(100) NOT NULL,
    MODEL_TYPE VARCHAR(50) NOT NULL,
    ALGORITHM VARCHAR(50) NOT NULL,
    VERSION VARCHAR(20) NOT NULL,
    TRAINING_DATE TIMESTAMP_NTZ NOT NULL,
    MODEL_OBJECT VARCHAR(16777216),
    FEATURE_SCHEMA VARIANT,
    HYPERPARAMETERS VARIANT,
    TRAINING_METRICS VARIANT,
    STATUS VARCHAR(20) DEFAULT 'TRAINING',
    CREATED_BY VARCHAR(100),
    CREATED_TS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DEPLOYED_TS TIMESTAMP_NTZ
)
COMMENT = 'ML model registry with versions and metadata';

-- Model Predictions
CREATE OR REPLACE TABLE MODEL_PREDICTIONS (
    PREDICTION_ID NUMBER(38,0) AUTOINCREMENT PRIMARY KEY,
    ASSET_ID VARCHAR(50) NOT NULL,
    PREDICTION_TIMESTAMP TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    MODEL_ID VARCHAR(50) NOT NULL,
    
    -- Model Outputs
    ANOMALY_SCORE NUMBER(5,4),
    FAILURE_PROBABILITY NUMBER(5,4),
    PREDICTED_RUL_DAYS NUMBER(10,2),
    RISK_SCORE NUMBER(5,2),
    CONFIDENCE NUMBER(5,4),
    
    -- Features Used
    FEATURE_VALUES VARIANT,
    
    -- Alert Status
    ALERT_GENERATED BOOLEAN DEFAULT FALSE,
    ALERT_LEVEL VARCHAR(20),
    
    CREATED_TS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Real-time ML predictions and risk scores'
CLUSTER BY (PREDICTION_TIMESTAMP, ASSET_ID);

-- Feature Importance
CREATE OR REPLACE TABLE FEATURE_IMPORTANCE (
    IMPORTANCE_ID NUMBER(38,0) AUTOINCREMENT PRIMARY KEY,
    MODEL_ID VARCHAR(50) NOT NULL,
    FEATURE_NAME VARCHAR(100) NOT NULL,
    IMPORTANCE_SCORE NUMBER(10,6),
    IMPORTANCE_RANK NUMBER(10),
    COMPUTATION_DATE DATE NOT NULL
)
COMMENT = 'Feature importance scores for model explainability';

-- =============================================================================
-- SECTION 5: REFERENCE DATA
-- =============================================================================

USE SCHEMA RAW;

-- Failure Type Reference
CREATE OR REPLACE TABLE FAILURE_TYPE_REFERENCE (
    FAILURE_TYPE_CODE VARCHAR(20) PRIMARY KEY,
    FAILURE_TYPE_NAME VARCHAR(100),
    DESCRIPTION VARCHAR(500),
    TYPICAL_ROOT_CAUSES VARIANT,
    AVG_REPAIR_COST_USD NUMBER(12,2),
    AVG_DOWNTIME_HOURS NUMBER(5,2)
);

INSERT INTO FAILURE_TYPE_REFERENCE 
SELECT 'BEARING_WEAR', 'Bearing Wear', 'Progressive bearing degradation from friction and fatigue',
    PARSE_JSON('["Lubrication failure", "Contamination", "Overloading", "Misalignment"]'), 8500, 6.0
UNION ALL
SELECT 'MOTOR_OVERLOAD', 'Motor Overload', 'Motor thermal or electrical overload condition',
    PARSE_JSON('["Blocked conveyor", "Mechanical binding", "Voltage issues", "Cooling failure"]'), 12000, 8.0
UNION ALL
SELECT 'BRACKET_LOOSE', 'Loose Bracket/Mount', 'Mounting hardware loosening from vibration',
    PARSE_JSON('["Vibration fatigue", "Improper torque", "Material fatigue"]'), 3500, 4.0
UNION ALL
SELECT 'ELECTRICAL_FAULT', 'Electrical Fault', 'Electrical component failure or wiring issue',
    PARSE_JSON('["Insulation breakdown", "Loose connections", "Component aging"]'), 15000, 10.0
UNION ALL
SELECT 'SEAL_LEAK', 'Seal/Gasket Leak', 'Pressure boundary leak from seal degradation',
    PARSE_JSON('["Thermal cycling", "Chemical exposure", "Age hardening"]'), 5000, 5.0
UNION ALL
SELECT 'SENSOR_DRIFT', 'Sensor Drift', 'Instrumentation calibration drift',
    PARSE_JSON('["Environmental exposure", "Component aging", "Contamination"]'), 2000, 2.0;

-- =============================================================================
-- SECTION 6: STAGING TABLES
-- =============================================================================

USE SCHEMA STAGING;

CREATE OR REPLACE TABLE SENSOR_STAGING (
    STAGING_ID NUMBER(38,0) AUTOINCREMENT PRIMARY KEY,
    RAW_DATA VARIANT NOT NULL,
    SOURCE_FILE VARCHAR(500),
    INGESTION_TS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PROCESSED BOOLEAN DEFAULT FALSE,
    ERROR_MESSAGE VARCHAR(5000)
)
COMMENT = 'Staging table for sensor data ingestion';

-- =============================================================================
-- SECTION 7: HELPER FUNCTIONS
-- =============================================================================

USE SCHEMA RAW;

CREATE OR REPLACE FUNCTION CALCULATE_ASSET_AGE(INSTALL_DATE DATE)
RETURNS NUMBER(5,2)
LANGUAGE SQL
AS
$$
    DATEDIFF(day, INSTALL_DATE, CURRENT_DATE()) / 365.25
$$;

CREATE OR REPLACE FUNCTION CALCULATE_DAYS_SINCE_MAINTENANCE(LAST_MAINT_DATE DATE)
RETURNS NUMBER(10)
LANGUAGE SQL
AS
$$
    DATEDIFF(day, LAST_MAINT_DATE, CURRENT_DATE())
$$;

-- =============================================================================
-- VERIFICATION
-- =============================================================================

SELECT 'Infrastructure setup complete!' as STATUS;
SELECT 'Database: STERIS_RELIABILITY_DB' as DATABASE_NAME;
SELECT 'Schemas: RAW, FEATURES, ML, ANALYTICS, UNSTRUCTURED, STAGING' as SCHEMAS;
