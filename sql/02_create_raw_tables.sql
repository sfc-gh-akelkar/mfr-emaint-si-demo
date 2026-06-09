-- ============================================================================
-- MFR "Factory of the Future" AI Reliability Platform
-- Step 2: Create Raw Data Tables and Insert Data
-- ============================================================================
-- This script creates the raw data tables and inserts all demo data directly.
-- No CSV files or staging required - just run this SQL!
-- ============================================================================

USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE MFR_RELIABILITY_DB;
USE SCHEMA RAW_DATA;
USE WAREHOUSE MFR_ANALYTICS_WH;

-- ============================================================================
-- Table 1: eMaint Assets - Equipment Master Data
-- ============================================================================
CREATE OR REPLACE TABLE EMAINT_ASSETS (
    ASSET_ID VARCHAR(20) PRIMARY KEY,
    ASSET_NAME VARCHAR(100) NOT NULL,
    ASSET_TYPE VARCHAR(50) NOT NULL,
    MANUFACTURER VARCHAR(50),
    MODEL VARCHAR(50),
    SERIAL_NUMBER VARCHAR(50),
    LOCATION VARCHAR(100),
    PLANT VARCHAR(50) NOT NULL,
    INSTALLATION_DATE DATE,
    LAST_MAINTENANCE_DATE DATE,
    ASSET_STATUS VARCHAR(20),
    CRITICALITY VARCHAR(20),
    EXPECTED_LIFE_YEARS NUMBER(5,1),
    CURRENT_AGE_YEARS NUMBER(5,1),
    ASSET_HEALTH_SCORE NUMBER(5,2)
)
COMMENT = 'MFR equipment master data from eMaint CMMS including sterilizers, washers, and packaging systems';

-- Add column comments for semantic context
COMMENT ON COLUMN EMAINT_ASSETS.ASSET_ID IS 'Unique identifier for each asset in eMaint system';
COMMENT ON COLUMN EMAINT_ASSETS.ASSET_NAME IS 'Human-readable name of the equipment';
COMMENT ON COLUMN EMAINT_ASSETS.ASSET_TYPE IS 'Category of equipment: Steam Sterilizer, Washer-Disinfector, Packaging System, Low-Temp Sterilizer, or Utility System';
COMMENT ON COLUMN EMAINT_ASSETS.MANUFACTURER IS 'Equipment manufacturer - primarily MFR for core equipment';
COMMENT ON COLUMN EMAINT_ASSETS.MODEL IS 'Specific model designation (e.g., AMSCO Century V116, Reliance 444, Novus 600)';
COMMENT ON COLUMN EMAINT_ASSETS.SERIAL_NUMBER IS 'Factory serial number for equipment tracking';
COMMENT ON COLUMN EMAINT_ASSETS.LOCATION IS 'Physical location within the plant facility';
COMMENT ON COLUMN EMAINT_ASSETS.PLANT IS 'Facility identifier: Plant A (legacy), Plant B (legacy), or Hendrix (new lighthouse facility)';
COMMENT ON COLUMN EMAINT_ASSETS.INSTALLATION_DATE IS 'Date when equipment was installed and commissioned';
COMMENT ON COLUMN EMAINT_ASSETS.LAST_MAINTENANCE_DATE IS 'Date of most recent maintenance activity';
COMMENT ON COLUMN EMAINT_ASSETS.ASSET_STATUS IS 'Current operational status: Operational, Warning, or Down';
COMMENT ON COLUMN EMAINT_ASSETS.CRITICALITY IS 'Business criticality level: Critical, High, Medium, or Low';
COMMENT ON COLUMN EMAINT_ASSETS.EXPECTED_LIFE_YEARS IS 'Expected useful life of the asset in years';
COMMENT ON COLUMN EMAINT_ASSETS.CURRENT_AGE_YEARS IS 'Current age of the asset since installation';
COMMENT ON COLUMN EMAINT_ASSETS.ASSET_HEALTH_SCORE IS 'Calculated health score from 0-100 based on age, maintenance history, and telemetry';

-- Insert Assets Data
INSERT INTO EMAINT_ASSETS (ASSET_ID, ASSET_NAME, ASSET_TYPE, MANUFACTURER, MODEL, SERIAL_NUMBER, LOCATION, PLANT, INSTALLATION_DATE, LAST_MAINTENANCE_DATE, ASSET_STATUS, CRITICALITY, EXPECTED_LIFE_YEARS, CURRENT_AGE_YEARS, ASSET_HEALTH_SCORE) VALUES
('AST-001', 'AMSCO Sterilizer 01', 'Steam Sterilizer', 'MFR', 'AMSCO Century V116', 'SN-2019-00145', 'Production Line 1', 'Plant A', '2019-03-15', '2025-11-20', 'Operational', 'Critical', 15, 5.8, 87),
('AST-002', 'AMSCO Sterilizer 02', 'Steam Sterilizer', 'MFR', 'AMSCO Century V116', 'SN-2019-00146', 'Production Line 1', 'Plant A', '2019-03-22', '2025-12-01', 'Operational', 'Critical', 15, 5.8, 92),
('AST-003', 'AMSCO Sterilizer 03', 'Steam Sterilizer', 'MFR', 'AMSCO Century V120', 'SN-2020-00087', 'Production Line 2', 'Plant A', '2020-06-10', '2025-10-15', 'Operational', 'Critical', 15, 4.6, 89),
('AST-004', 'Reliance Washer 01', 'Washer-Disinfector', 'MFR', 'Reliance 444', 'SN-2018-00234', 'Decontamination Area', 'Plant A', '2018-08-20', '2025-11-28', 'Operational', 'High', 12, 6.4, 78),
('AST-005', 'Reliance Washer 02', 'Washer-Disinfector', 'MFR', 'Reliance 444', 'SN-2018-00235', 'Decontamination Area', 'Plant A', '2018-08-25', '2025-12-10', 'Operational', 'High', 12, 6.4, 81),
('AST-006', 'Reliance Washer 03', 'Washer-Disinfector', 'MFR', 'Reliance 500', 'SN-2021-00098', 'Decontamination Area', 'Plant B', '2021-02-14', '2025-11-05', 'Operational', 'High', 12, 3.9, 94),
('AST-007', 'AMSCO Sterilizer 04', 'Steam Sterilizer', 'MFR', 'AMSCO Century V116', 'SN-2017-00067', 'Production Line 1', 'Plant B', '2017-11-03', '2025-10-22', 'Operational', 'Critical', 15, 7.2, 72),
('AST-008', 'AMSCO Sterilizer 05', 'Steam Sterilizer', 'MFR', 'AMSCO Century V120', 'SN-2021-00134', 'Production Line 2', 'Plant B', '2021-04-18', '2025-12-05', 'Operational', 'Critical', 15, 3.7, 96),
('AST-009', 'Novus 600 Packaging 01', 'Packaging System', 'MFR', 'Novus 600', 'SN-2022-00056', 'Packaging Area', 'Plant B', '2022-01-10', '2025-12-15', 'Operational', 'Critical', 10, 2.9, 71),
('AST-010', 'Novus 600 Packaging 02', 'Packaging System', 'MFR', 'Novus 600', 'SN-2023-00012', 'Packaging Area', 'Hendrix', '2023-06-15', '2025-12-20', 'Warning', 'Critical', 10, 1.5, 65),
('AST-011', 'AMSCO Sterilizer 06', 'Steam Sterilizer', 'MFR', 'AMSCO Evolution', 'SN-2024-00001', 'Sterile Processing', 'Hendrix', '2024-01-08', '2025-11-30', 'Operational', 'Critical', 15, 0.9, 99),
('AST-012', 'AMSCO Sterilizer 07', 'Steam Sterilizer', 'MFR', 'AMSCO Evolution', 'SN-2024-00002', 'Sterile Processing', 'Hendrix', '2024-01-15', '2025-12-01', 'Operational', 'Critical', 15, 0.9, 98),
('AST-013', 'Reliance Washer 04', 'Washer-Disinfector', 'MFR', 'Reliance 600', 'SN-2024-00015', 'Central Processing', 'Hendrix', '2024-02-20', '2025-11-25', 'Operational', 'High', 12, 0.8, 99),
('AST-014', 'Reliance Washer 05', 'Washer-Disinfector', 'MFR', 'Reliance 600', 'SN-2024-00016', 'Central Processing', 'Hendrix', '2024-02-25', '2025-11-28', 'Operational', 'High', 12, 0.8, 98),
('AST-015', 'Novus 600 Packaging 03', 'Packaging System', 'MFR', 'Novus 600', 'SN-2024-00045', 'Packaging Line 1', 'Hendrix', '2024-03-10', '2025-12-28', 'Operational', 'Critical', 10, 0.8, 97),
('AST-016', 'V-PRO Low Temp 01', 'Low-Temp Sterilizer', 'MFR', 'V-PRO maX', 'SN-2023-00078', 'Low-Temp Suite', 'Hendrix', '2023-09-01', '2025-11-15', 'Operational', 'Critical', 10, 1.3, 95),
('AST-017', 'V-PRO Low Temp 02', 'Low-Temp Sterilizer', 'MFR', 'V-PRO maX', 'SN-2024-00089', 'Low-Temp Suite', 'Hendrix', '2024-04-12', '2025-12-10', 'Operational', 'Critical', 10, 0.7, 99),
('AST-018', 'Compressed Air System', 'Utility System', 'Atlas Copco', 'GA45VSD', 'SN-2019-00456', 'Utility Room', 'Plant A', '2019-05-20', '2025-10-30', 'Operational', 'High', 20, 5.6, 85),
('AST-019', 'Boiler System 01', 'Utility System', 'Cleaver-Brooks', 'CB-700', 'SN-2017-00123', 'Boiler Room', 'Plant A', '2017-03-10', '2025-11-01', 'Operational', 'Critical', 25, 7.8, 79),
('AST-020', 'Boiler System 02', 'Utility System', 'Cleaver-Brooks', 'CB-900', 'SN-2024-00003', 'Utility Center', 'Hendrix', '2024-01-20', '2025-12-15', 'Operational', 'Critical', 25, 0.9, 99);

-- ============================================================================
-- Table 2: eMaint Work Orders - Maintenance History
-- ============================================================================
CREATE OR REPLACE TABLE EMAINT_WORK_ORDERS (
    WO_ID VARCHAR(20) PRIMARY KEY,
    ASSET_ID VARCHAR(20) NOT NULL,
    WO_TYPE VARCHAR(20) NOT NULL,
    WORK_DESCRIPTION VARCHAR(500),
    FAILURE_CODE VARCHAR(20),
    ROOT_CAUSE VARCHAR(100),
    PRIORITY VARCHAR(20),
    STATUS VARCHAR(20) NOT NULL,
    CREATED_DATE DATE NOT NULL,
    SCHEDULED_DATE DATE,
    COMPLETED_DATE DATE,
    TECHNICIAN VARCHAR(100),
    LABOR_HOURS NUMBER(5,1),
    PARTS_COST NUMBER(10,2),
    LABOR_COST NUMBER(10,2),
    TOTAL_REPAIR_COST NUMBER(10,2),
    MTTR_HOURS NUMBER(5,1),
    DOWNTIME_HOURS NUMBER(5,1),
    FOREIGN KEY (ASSET_ID) REFERENCES EMAINT_ASSETS(ASSET_ID)
)
COMMENT = 'Work order history from eMaint CMMS tracking all corrective and preventive maintenance';

-- Add column comments for semantic context
COMMENT ON COLUMN EMAINT_WORK_ORDERS.WO_ID IS 'Unique work order identifier';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.ASSET_ID IS 'Reference to the asset being maintained';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.WO_TYPE IS 'Type of work order: Corrective (breakdown), Preventive (scheduled PM), Emergency, or Investigation';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.WORK_DESCRIPTION IS 'Detailed description of the maintenance work performed';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.FAILURE_CODE IS 'Standardized failure code (e.g., STM-FAIL for steam failure, VIB-09 for vibration issues)';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.ROOT_CAUSE IS 'Identified root cause of the failure';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.PRIORITY IS 'Work priority: Critical, High, Medium, or Low';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.STATUS IS 'Work order status: Open, Scheduled, In Progress, Completed, or Cancelled';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.CREATED_DATE IS 'Date when the work order was created';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.SCHEDULED_DATE IS 'Planned date for maintenance execution';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.COMPLETED_DATE IS 'Actual completion date of the work';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.TECHNICIAN IS 'Name of the maintenance technician assigned';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.LABOR_HOURS IS 'Total labor hours spent on the repair';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.PARTS_COST IS 'Cost of replacement parts and materials in USD';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.LABOR_COST IS 'Cost of labor at $75/hour in USD';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.TOTAL_REPAIR_COST IS 'Total repair cost (parts + labor) in USD';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.MTTR_HOURS IS 'Mean Time To Repair - hours from work start to completion';
COMMENT ON COLUMN EMAINT_WORK_ORDERS.DOWNTIME_HOURS IS 'Total equipment downtime in hours including wait and repair time';

-- Insert Work Orders Data
INSERT INTO EMAINT_WORK_ORDERS (WO_ID, ASSET_ID, WO_TYPE, WORK_DESCRIPTION, FAILURE_CODE, ROOT_CAUSE, PRIORITY, STATUS, CREATED_DATE, SCHEDULED_DATE, COMPLETED_DATE, TECHNICIAN, LABOR_HOURS, PARTS_COST, LABOR_COST, TOTAL_REPAIR_COST, MTTR_HOURS, DOWNTIME_HOURS) VALUES
('WO-2024-0001', 'AST-001', 'Corrective', 'Steam valve replacement due to pressure fluctuation', 'STM-FAIL', 'Worn valve seat', 'High', 'Completed', '2024-03-10', '2024-03-11', '2024-03-11', 'John Martinez', 4.5, 875.00, 337.50, 1212.50, 4.5, 6.0),
('WO-2024-0002', 'AST-004', 'Preventive', 'Quarterly maintenance - pump inspection and filter replacement', 'PM-QTRLY', 'Scheduled', 'Medium', 'Completed', '2024-03-15', '2024-03-16', '2024-03-16', 'Sarah Chen', 2.0, 125.00, 150.00, 275.00, 2.0, 2.5),
('WO-2024-0003', 'AST-007', 'Corrective', 'Door gasket replacement - seal failure detected', 'SEAL-FAIL', 'Age-related degradation', 'High', 'Completed', '2024-04-02', '2024-04-03', '2024-04-03', 'Mike Thompson', 3.0, 450.00, 225.00, 675.00, 3.0, 4.0),
('WO-2024-0004', 'AST-009', 'Corrective', 'Bearing replacement - vibration detected', 'VIB-09', 'Bearing wear', 'Critical', 'Completed', '2024-04-18', '2024-04-18', '2024-04-19', 'Robert Wilson', 6.0, 320.00, 450.00, 770.00, 6.0, 8.0),
('WO-2024-0005', 'AST-002', 'Preventive', 'Annual sterilizer validation and calibration', 'PM-ANNUAL', 'Scheduled', 'Medium', 'Completed', '2024-05-01', '2024-05-02', '2024-05-02', 'John Martinez', 5.0, 200.00, 375.00, 575.00, 5.0, 6.0),
('WO-2024-0006', 'AST-006', 'Corrective', 'Water pump motor replacement', 'PUMP-FAIL', 'Motor burnout', 'High', 'Completed', '2024-05-15', '2024-05-16', '2024-05-16', 'Sarah Chen', 4.0, 1250.00, 300.00, 1550.00, 4.0, 5.5),
('WO-2024-0007', 'AST-010', 'Corrective', 'Pneumatic actuator adjustment - packaging misalignment', 'MECH-ALIGN', 'Actuator drift', 'High', 'Completed', '2024-06-01', '2024-06-01', '2024-06-02', 'Luis Garcia', 5.5, 180.00, 412.50, 592.50, 5.5, 7.0),
('WO-2024-0008', 'AST-003', 'Preventive', 'Bi-annual chamber inspection and sensor calibration', 'PM-BIANN', 'Scheduled', 'Medium', 'Completed', '2024-06-10', '2024-06-11', '2024-06-11', 'Mike Thompson', 3.5, 95.00, 262.50, 357.50, 3.5, 4.0),
('WO-2024-0009', 'AST-011', 'Preventive', 'First 90-day inspection - new equipment', 'PM-90DAY', 'Scheduled', 'Low', 'Completed', '2024-04-10', '2024-04-10', '2024-04-10', 'Robert Wilson', 1.5, 0.00, 112.50, 112.50, 1.5, 2.0),
('WO-2024-0010', 'AST-008', 'Corrective', 'Control board replacement - intermittent display failure', 'ELEC-CTRL', 'Component failure', 'High', 'Completed', '2024-07-05', '2024-07-06', '2024-07-07', 'John Martinez', 8.0, 2100.00, 600.00, 2700.00, 8.0, 12.0),
('WO-2024-0011', 'AST-005', 'Corrective', 'Drain line clog - drainage slow', 'DRAIN-CLG', 'Scale buildup', 'Medium', 'Completed', '2024-07-20', '2024-07-21', '2024-07-21', 'Sarah Chen', 2.5, 45.00, 187.50, 232.50, 2.5, 3.0),
('WO-2024-0012', 'AST-009', 'Corrective', 'Wobbling issue persists - realigned pneumatic actuator bracket', 'VIB-09', 'Bracket misalignment', 'Critical', 'Completed', '2024-08-10', '2024-08-10', '2024-08-11', 'Luis Garcia', 7.0, 225.00, 525.00, 750.00, 7.0, 9.0),
('WO-2024-0013', 'AST-013', 'Preventive', 'Initial 30-day inspection - new washer', 'PM-30DAY', 'Scheduled', 'Low', 'Completed', '2024-03-22', '2024-03-22', '2024-03-22', 'Robert Wilson', 1.0, 0.00, 75.00, 75.00, 1.0, 1.5),
('WO-2024-0014', 'AST-016', 'Preventive', 'Quarterly H2O2 injector calibration', 'PM-QTRLY', 'Scheduled', 'Medium', 'Completed', '2024-12-01', '2024-12-02', '2024-12-02', 'Mike Thompson', 2.5, 180.00, 187.50, 367.50, 2.5, 3.0),
('WO-2024-0015', 'AST-001', 'Preventive', 'Semi-annual comprehensive maintenance', 'PM-BIANN', 'Scheduled', 'Medium', 'Completed', '2024-09-15', '2024-09-16', '2024-09-16', 'John Martinez', 6.0, 350.00, 450.00, 800.00, 6.0, 8.0),
('WO-2024-0016', 'AST-018', 'Corrective', 'Air dryer filter replacement - moisture detected', 'UTIL-AIR', 'Filter saturation', 'Medium', 'Completed', '2024-09-25', '2024-09-26', '2024-09-26', 'Sarah Chen', 2.0, 280.00, 150.00, 430.00, 2.0, 2.5),
('WO-2024-0017', 'AST-019', 'Corrective', 'Burner tune-up - efficiency drop detected', 'UTIL-FUEL', 'Combustion efficiency', 'High', 'Completed', '2024-10-05', '2024-10-06', '2024-10-06', 'External Contractor', 4.0, 150.00, 800.00, 950.00, 4.0, 5.0),
('WO-2024-0018', 'AST-010', 'Corrective', 'Bearing replacement attempt - wobbling continues', 'VIB-09', 'Misdiagnosis', 'Critical', 'Completed', '2024-10-15', '2024-10-15', '2024-10-16', 'Robert Wilson', 5.0, 420.00, 375.00, 795.00, 5.0, 6.5),
('WO-2024-0019', 'AST-012', 'Preventive', 'Quarterly filter and gasket inspection', 'PM-QTRLY', 'Scheduled', 'Medium', 'Completed', '2024-10-20', '2024-10-21', '2024-10-21', 'John Martinez', 2.0, 85.00, 150.00, 235.00, 2.0, 2.5),
('WO-2024-0020', 'AST-014', 'Preventive', 'First quarterly maintenance - new equipment', 'PM-QTRLY', 'Scheduled', 'Medium', 'Completed', '2024-05-28', '2024-05-29', '2024-05-29', 'Sarah Chen', 2.5, 65.00, 187.50, 252.50, 2.5, 3.0),
('WO-2024-0021', 'AST-007', 'Corrective', 'Steam trap replacement - condensate backup', 'STM-TRAP', 'Trap failure', 'High', 'Completed', '2024-11-01', '2024-11-02', '2024-11-02', 'Mike Thompson', 3.5, 380.00, 262.50, 642.50, 3.5, 4.5),
('WO-2024-0022', 'AST-004', 'Corrective', 'Spray arm bearing replacement', 'MECH-BEAR', 'Normal wear', 'Medium', 'Completed', '2024-11-10', '2024-11-11', '2024-11-11', 'Luis Garcia', 2.5, 195.00, 187.50, 382.50, 2.5, 3.0),
('WO-2024-0023', 'AST-010', 'Emergency', 'Pneumatic actuator bracket realignment - wobbling fix', 'VIB-09', 'Bracket loosening', 'Critical', 'Completed', '2025-01-02', '2025-01-02', '2025-01-02', 'Luis Garcia', 4.0, 125.00, 300.00, 425.00, 4.0, 5.0),
('WO-2024-0024', 'AST-015', 'Preventive', 'First quarterly calibration and inspection', 'PM-QTRLY', 'Scheduled', 'Medium', 'Completed', '2024-06-12', '2024-06-13', '2024-06-13', 'Robert Wilson', 2.0, 45.00, 150.00, 195.00, 2.0, 2.5),
('WO-2024-0025', 'AST-017', 'Preventive', 'Initial commissioning verification', 'PM-COMM', 'Scheduled', 'Low', 'Completed', '2024-04-15', '2024-04-15', '2024-04-15', 'John Martinez', 1.5, 0.00, 112.50, 112.50, 1.5, 2.0),
('WO-2025-0001', 'AST-010', 'Investigation', 'Vibration spike detected 4.5mm/s - investigation pending', 'VIB-09', 'Under investigation', 'Critical', 'Open', '2025-01-02', '2025-01-02', NULL, 'Luis Garcia', 0.0, 0.00, 0.00, 0.00, 0.0, 0.0),
('WO-2025-0002', 'AST-002', 'Preventive', 'Q1 2025 Preventive Maintenance', 'PM-QTRLY', 'Scheduled', 'Medium', 'Scheduled', '2025-01-10', '2025-01-15', NULL, NULL, 0.0, 0.00, 0.00, 0.00, 0.0, 0.0),
('WO-2025-0003', 'AST-011', 'Preventive', 'Annual comprehensive inspection', 'PM-ANNUAL', 'Scheduled', 'Medium', 'Scheduled', '2025-01-08', '2025-01-20', NULL, NULL, 0.0, 0.00, 0.00, 0.00, 0.0, 0.0);

-- ============================================================================
-- Table 3: Technician Notes - Unstructured Logbook Entries
-- ============================================================================
CREATE OR REPLACE TABLE TECH_NOTES_UNSTRUCTURED (
    NOTE_ID VARCHAR(20) PRIMARY KEY,
    ASSET_ID VARCHAR(20),
    WO_ID VARCHAR(20),
    TECHNICIAN VARCHAR(100),
    NOTE_DATE DATE NOT NULL,
    NOTE_TEXT VARCHAR(2000) NOT NULL
)
COMMENT = 'Raw technician logbook entries containing troubleshooting notes, observations, and tribal knowledge';

COMMENT ON COLUMN TECH_NOTES_UNSTRUCTURED.NOTE_ID IS 'Unique identifier for each technician note';
COMMENT ON COLUMN TECH_NOTES_UNSTRUCTURED.ASSET_ID IS 'Reference to the asset discussed in the note';
COMMENT ON COLUMN TECH_NOTES_UNSTRUCTURED.WO_ID IS 'Optional reference to associated work order';
COMMENT ON COLUMN TECH_NOTES_UNSTRUCTURED.TECHNICIAN IS 'Name of the technician who wrote the note';
COMMENT ON COLUMN TECH_NOTES_UNSTRUCTURED.NOTE_DATE IS 'Date when the note was recorded';
COMMENT ON COLUMN TECH_NOTES_UNSTRUCTURED.NOTE_TEXT IS 'Full text of the technician note containing troubleshooting details, fixes, and observations';

-- Insert Technician Notes Data
INSERT INTO TECH_NOTES_UNSTRUCTURED (NOTE_ID, ASSET_ID, WO_ID, TECHNICIAN, NOTE_DATE, NOTE_TEXT) VALUES
('TN-001', 'AST-001', 'WO-2024-0001', 'John Martinez', '2024-03-11', 'Replaced steam valve on AMSCO Sterilizer 01. Found significant wear on the valve seat - appears to be from thermal cycling. Recommend monitoring pressure readings more frequently. Valve part #SV-2458 installed. System tested at 275F for 30 minutes with no leaks.'),
('TN-002', 'AST-004', 'WO-2024-0002', 'Sarah Chen', '2024-03-16', 'Completed quarterly PM on Reliance Washer 01. Replaced main filter cartridge and inspected circulation pump. Pump impeller showing minor wear but within spec. All spray arms rotating freely. Water temp calibration verified at 180F +/-2.'),
('TN-003', 'AST-007', 'WO-2024-0003', 'Mike Thompson', '2024-04-03', 'Door gasket on AMSCO Sterilizer 04 was cracked and hardened. This unit is getting older - 7 years in service. Replaced with new silicone gasket P/N DG-7890. Door seal test passed. Recommend adding this unit to enhanced monitoring list.'),
('TN-004', 'AST-009', 'WO-2024-0004', 'Robert Wilson', '2024-04-19', 'Novus 600 Packaging 01 at Plant B showing elevated vibration readings. Replaced main drive bearings as suspected. Vibration reduced from 3.8mm/s to 1.2mm/s after replacement. Will monitor for 48 hours.'),
('TN-005', 'AST-002', 'WO-2024-0005', 'John Martinez', '2024-05-02', 'Annual validation complete on AMSCO Sterilizer 02. All temperature probes within +/-0.5C. Biological indicators passed. Chamber door microswitches adjusted. Printed and filed validation report.'),
('TN-006', 'AST-006', 'WO-2024-0006', 'Sarah Chen', '2024-05-16', 'Water pump motor on Reliance Washer 03 completely burnt out. Found evidence of water ingress into motor housing - seal around shaft was deteriorated. Installed new motor assembly. Added note to check shaft seals on all Reliance units during next PM.'),
('TN-007', 'AST-010', 'WO-2024-0007', 'Luis Garcia', '2024-06-02', 'Novus 600 Packaging 02 at Hendrix facility having alignment issues. Packages coming out slightly crooked. Adjusted pneumatic actuator position sensors. Alignment improved but machine still showing slight wobble during operation. Will need to investigate further.'),
('TN-008', 'AST-003', 'WO-2024-0008', 'Mike Thompson', '2024-06-11', 'Bi-annual inspection on AMSCO Sterilizer 03. Chamber walls clean, no scale buildup. Replaced 2 thermocouples that were drifting. Pressure relief valve tested and certified. Unit running well.'),
('TN-009', 'AST-011', 'WO-2024-0009', 'Robert Wilson', '2024-04-10', 'First 90-day check on new AMSCO Evolution at Hendrix. Everything running perfectly. No issues to report. This new Evolution model runs much quieter than the older Century models.'),
('TN-010', 'AST-008', 'WO-2024-0010', 'John Martinez', '2024-07-07', 'Major repair on AMSCO Sterilizer 05. HMI display was intermittently blanking out. Traced to failing control board. Replaced entire PLC and HMI assembly - P/N CB-AMSCO-500. Took longer than expected due to software configuration.'),
('TN-011', 'AST-005', 'WO-2024-0011', 'Sarah Chen', '2024-07-21', 'Drain line on Reliance Washer 02 was partially clogged. Found calcium scale buildup - water hardness may be high at this location. Cleaned line with descaling solution. Recommend installing water softener upstream.'),
('TN-012', 'AST-009', 'WO-2024-0004', 'Robert Wilson', '2024-04-22', 'Follow-up on Novus 600 Packaging 01. Vibration readings stable at 1.1mm/s after 72 hours. Bearing replacement appears successful. Returning to normal monitoring schedule.'),
('TN-013', 'AST-010', 'WO-2024-0012', 'Luis Garcia', '2024-08-11', 'Back at Novus 600 Packaging 02. Wobbling issue returned after 6 weeks. Standard bearing check showed they are fine. After extensive troubleshooting, discovered the pneumatic actuator BRACKET itself was loose and allowing play. Realigned and torqued the bracket mounting bolts to 45 ft-lbs. This was the root cause all along - NOT the bearings.'),
('TN-014', 'AST-013', 'WO-2024-0013', 'Robert Wilson', '2024-03-22', 'Initial inspection on new Reliance 600 at Hendrix. Unit installed correctly. All connections tight. Software version 4.2.1 confirmed. Ran 3 test cycles - all parameters within spec.'),
('TN-015', 'AST-016', 'WO-2024-0014', 'Mike Thompson', '2024-12-02', 'Quarterly calibration on V-PRO maX unit 01. H2O2 injector flow rate verified at 1.8mL/cycle +/-0.1. Chamber vacuum holding at 0.1 Torr. Replaced desiccant in vaporizer chamber as scheduled.'),
('TN-016', 'AST-001', 'WO-2024-0015', 'John Martinez', '2024-09-16', 'Semi-annual PM on AMSCO Sterilizer 01. Replaced door gasket proactively - was showing early signs of hardening. All safety interlocks tested. Jacket pressure relief valve replaced per schedule.'),
('TN-017', 'AST-018', 'WO-2024-0016', 'Sarah Chen', '2024-09-26', 'Air dryer on compressed air system flagging moisture alarm. Regeneration cycle not completing properly. Replaced desiccant filter cartridges. Dew point now reading -40F. Good to go.'),
('TN-018', 'AST-019', 'WO-2024-0017', 'External Contractor', '2024-10-06', 'Boiler 01 at Plant A running at 78% efficiency - should be 85%+. Performed burner tune-up, adjusted air/fuel ratio. Cleaned flame scanner lens. Efficiency now at 86%. Scheduled full inspection for Q1 2025.'),
('TN-019', 'AST-010', 'WO-2024-0018', 'Robert Wilson', '2024-10-16', 'Returned to Novus 600 Packaging 02 - wobbling back again! Luis mentioned he fixed it before but it is recurring. Replaced bearings as a precaution but the real problem seems mechanical, not bearings. Need Luis to show me what he found last time.'),
('TN-020', 'AST-012', 'WO-2024-0019', 'John Martinez', '2024-10-21', 'Quarterly PM on AMSCO Evolution 07 at Hendrix. New unit still in break-in period. All gaskets and filters in excellent condition. Updated firmware to latest version 3.1.4.'),
('TN-021', 'AST-014', 'WO-2024-0020', 'Sarah Chen', '2024-05-29', 'First quarterly on Reliance 600 at Hendrix central processing. Unit running great. Water quality sensors all calibrated. Drain heater functioning properly.'),
('TN-022', 'AST-007', 'WO-2024-0021', 'Mike Thompson', '2024-11-02', 'Steam trap on AMSCO Sterilizer 04 failed in closed position. Caused condensate to back up into chamber. Replaced with ball float trap P/N ST-3456. May want to consider bucket traps for this older unit.'),
('TN-023', 'AST-004', 'WO-2024-0022', 'Luis Garcia', '2024-11-11', 'Spray arm bearing on Reliance 444 was making grinding noise. Replaced both upper and lower spray arm bearings. Arms now spinning smoothly. Checked alignment - all good.'),
('TN-024', 'AST-010', 'WO-2024-0023', 'Luis Garcia', '2025-01-02', 'Emergency call on Novus 600 Packaging 02 at Hendrix. Same wobbling issue from August. Found the pneumatic actuator bracket had loosened again. The bracket mounting holes may be slightly wallowed out from repeated loosening. Re-torqued all bolts and added thread locker. Recommend replacing the bracket plate entirely at next scheduled downtime.'),
('TN-025', 'AST-015', 'WO-2024-0024', 'Robert Wilson', '2024-06-13', 'First quarterly on Novus 600 Packaging 03 at Hendrix Packaging Line 1. All operating parameters nominal. Seal bars heating evenly. Conveyor speed calibrated.'),
('TN-026', 'AST-017', 'WO-2024-0025', 'John Martinez', '2024-04-15', 'Commissioning verification on V-PRO maX 02. All factory settings confirmed. Ran 5 complete cycles with biological indicators - all passed. Unit ready for production use.'),
('TN-027', 'AST-010', NULL, 'Luis Garcia', '2024-06-15', 'Side note on Novus 600 #02 - talked to operator Maria and she mentioned the wobbling started around the time they moved the machine for floor repainting. Worth investigating if the move caused the bracket issue.'),
('TN-028', 'AST-001', NULL, 'John Martinez', '2024-08-05', 'Noticed AMSCO Sterilizer 01 is running about 2 minutes longer per cycle lately. No alarms but worth watching. May need to check steam supply line for restrictions.'),
('TN-029', 'AST-007', NULL, 'Mike Thompson', '2024-09-15', 'Operator Tom reported occasional door not sealed alarm on AMSCO 04 that clears on retry. Could be dirty door sensor or early gasket wear. Will check at next PM.'),
('TN-030', 'AST-009', NULL, 'Robert Wilson', '2024-07-01', 'Novus 600 Packaging 01 at Plant B running smoothly since bearing replacement in April. Vibration steady at 1.0mm/s. Good outcome.'),
('TN-031', 'AST-010', NULL, 'Luis Garcia', '2024-09-05', 'Just a note - for Novus 600 machines showing wobbling issues, check the pneumatic actuator bracket FIRST before replacing bearings. Learned this the hard way on unit #02. The bracket has 4 mounting bolts that can work loose from vibration.'),
('TN-032', 'AST-002', NULL, 'John Martinez', '2024-11-10', 'Cycle counter on AMSCO Sterilizer 02 just hit 15,000 cycles. Unit still performing well but adding to list for enhanced monitoring.'),
('TN-033', 'AST-006', NULL, 'Sarah Chen', '2024-08-20', 'Following up on motor replacement - Reliance Washer 03 running great. No water ingress issues since shaft seal replacement. Water temp consistent.'),
('TN-034', 'AST-011', NULL, 'Robert Wilson', '2024-07-15', 'Hendrix operators really like the new Evolution sterilizers. Touch screen interface much more intuitive than old models. Training time cut in half.'),
('TN-035', 'AST-013', NULL, 'Sarah Chen', '2024-09-10', 'Random note - Reliance 600 units at Hendrix using about 15% less water per cycle than the older 444 models. Good for sustainability metrics.'),
('TN-036', 'AST-016', NULL, 'Mike Thompson', '2024-08-30', 'V-PRO units require very clean environment. Found dust accumulation near intake. Reminded cleaning crew to pay special attention to low-temp suite.'),
('TN-037', 'AST-018', NULL, 'Sarah Chen', '2024-07-10', 'Compressed air system dew point creeping up during humid months. May need additional drying capacity before next summer.'),
('TN-038', 'AST-019', NULL, 'External Contractor', '2024-06-15', 'Pre-summer boiler inspection at Plant A. System holding up but feedwater treatment showing some inconsistency. Recommended contacting water treatment vendor.'),
('TN-039', 'AST-003', NULL, 'Mike Thompson', '2024-08-01', 'Quick check on AMSCO Sterilizer 03 after operator reported unusual smell. Traced to small amount of residue from previous load. No equipment issue - advised on proper loading procedures.'),
('TN-040', 'AST-004', NULL, 'Luis Garcia', '2024-06-25', 'Noticed Reliance Washer 01 taking longer to drain. Not a problem yet but scheduling preventive drain cleaning at next PM.'),
('TN-041', 'AST-010', NULL, 'Production Team', '2024-12-20', 'Operator shift notes: Novus 600 #02 wobble acting up again. Can hear it during packaging cycle. Contacted maintenance.'),
('TN-042', 'AST-008', NULL, 'John Martinez', '2024-11-15', 'Post-repair follow-up on AMSCO Sterilizer 05. New control system running great. No display issues reported. Operators happy with improved response time.'),
('TN-043', 'AST-015', NULL, 'Robert Wilson', '2024-10-01', 'Novus 600 #03 at Hendrix hitting production targets consistently. Most reliable of the packaging units so far.'),
('TN-044', 'AST-012', NULL, 'John Martinez', '2024-08-20', 'AMSCO Evolution 07 firmware auto-update notification received. Will schedule update during next planned downtime.'),
('TN-045', 'AST-014', NULL, 'Sarah Chen', '2024-08-15', 'Water quality at Hendrix central processing better than Plant A. Less scaling expected on equipment here.'),
('TN-046', 'AST-020', NULL, 'External Contractor', '2024-06-01', 'New boiler at Hendrix passed initial efficiency test at 94%. Excellent performance. Setting up remote monitoring connection.'),
('TN-047', 'AST-010', NULL, 'Luis Garcia', '2024-11-20', 'Thinking about Novus 600 #02 wobble issue - the root cause is definitely the pneumatic actuator bracket. Standard troubleshooting would point to bearings but that is a red herring. For this specific machine, always check bracket torque first. 45 ft-lbs on all 4 bolts.'),
('TN-048', 'AST-005', NULL, 'Sarah Chen', '2024-10-15', 'Descaling treatment on Reliance Washer 02 seems to be holding. Drain flow normal.'),
('TN-049', 'AST-017', NULL, 'Mike Thompson', '2024-09-20', 'V-PRO #02 cycle times consistent. Chamber seal integrity excellent. These units are really well designed.'),
('TN-050', 'AST-010', 'WO-2025-0001', 'Luis Garcia', '2025-01-02', 'ALERT: Ignition system showing vibration spike to 4.5mm/s on Novus 600 #02. This is same machine with recurring bracket issue. Heading over now to check. Based on history, 90% sure it is the pneumatic actuator bracket loosening again. Will confirm and recommend permanent fix.');

-- ============================================================================
-- Table 4: Ignition SCADA Telemetry - Real-time Sensor Data
-- ============================================================================
CREATE OR REPLACE TABLE IGNITION_SCADA_TELEMETRY (
    TELEMETRY_ID VARCHAR(20) PRIMARY KEY,
    ASSET_ID VARCHAR(20) NOT NULL,
    SENSOR_TYPE VARCHAR(50) NOT NULL,
    SENSOR_NAME VARCHAR(50),
    READING_TIMESTAMP TIMESTAMP_NTZ NOT NULL,
    READING_VALUE NUMBER(10,2),
    UNIT VARCHAR(20),
    READING_QUALITY VARCHAR(20),
    ALARM_STATUS VARCHAR(20),
    ALARM_THRESHOLD NUMBER(10,2)
)
COMMENT = 'Time-series telemetry data from Ignition SCADA system including vibration, temperature, and pressure readings';

COMMENT ON COLUMN IGNITION_SCADA_TELEMETRY.TELEMETRY_ID IS 'Unique identifier for each telemetry reading';
COMMENT ON COLUMN IGNITION_SCADA_TELEMETRY.ASSET_ID IS 'Reference to the monitored asset';
COMMENT ON COLUMN IGNITION_SCADA_TELEMETRY.SENSOR_TYPE IS 'Type of sensor: Vibration, Temperature, Pressure, Vacuum, H2O2_Concentration, Dewpoint, or Efficiency';
COMMENT ON COLUMN IGNITION_SCADA_TELEMETRY.SENSOR_NAME IS 'Tag name of the sensor in Ignition';
COMMENT ON COLUMN IGNITION_SCADA_TELEMETRY.READING_TIMESTAMP IS 'Timestamp of the sensor reading';
COMMENT ON COLUMN IGNITION_SCADA_TELEMETRY.READING_VALUE IS 'Numeric value of the sensor reading';
COMMENT ON COLUMN IGNITION_SCADA_TELEMETRY.UNIT IS 'Unit of measurement (mm/s, F, PSI, Torr, mL, %)';
COMMENT ON COLUMN IGNITION_SCADA_TELEMETRY.READING_QUALITY IS 'Data quality indicator: Good, Uncertain, or Bad';
COMMENT ON COLUMN IGNITION_SCADA_TELEMETRY.ALARM_STATUS IS 'Current alarm state: Normal, Warning, High, or Critical';
COMMENT ON COLUMN IGNITION_SCADA_TELEMETRY.ALARM_THRESHOLD IS 'Configured alarm threshold for the sensor';

-- Insert Telemetry Data
INSERT INTO IGNITION_SCADA_TELEMETRY (TELEMETRY_ID, ASSET_ID, SENSOR_TYPE, SENSOR_NAME, READING_TIMESTAMP, READING_VALUE, UNIT, READING_QUALITY, ALARM_STATUS, ALARM_THRESHOLD) VALUES
('TEL-001', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 00:00:00', 1.2, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-002', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 01:00:00', 1.3, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-003', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 02:00:00', 1.2, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-004', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 03:00:00', 1.4, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-005', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 04:00:00', 1.5, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-006', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 05:00:00', 1.6, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-007', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 06:00:00', 1.8, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-008', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 07:00:00', 2.1, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-009', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 08:00:00', 2.4, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-010', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 09:00:00', 2.8, 'mm/s', 'Good', 'Warning', 3.5),
('TEL-011', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 10:00:00', 3.2, 'mm/s', 'Good', 'Warning', 3.5),
('TEL-012', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 11:00:00', 3.5, 'mm/s', 'Good', 'Warning', 3.5),
('TEL-013', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 12:00:00', 3.8, 'mm/s', 'Good', 'High', 3.5),
('TEL-014', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 13:00:00', 4.0, 'mm/s', 'Good', 'High', 3.5),
('TEL-015', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 14:00:00', 4.2, 'mm/s', 'Good', 'High', 3.5),
('TEL-016', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 15:00:00', 4.5, 'mm/s', 'Good', 'Critical', 3.5),
('TEL-017', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 16:00:00', 4.3, 'mm/s', 'Good', 'High', 3.5),
('TEL-018', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 17:00:00', 4.5, 'mm/s', 'Good', 'Critical', 3.5),
('TEL-019', 'AST-010', 'Temperature', 'TEMP_MOTOR', '2025-01-01 00:00:00', 145, 'F', 'Good', 'Normal', 180),
('TEL-020', 'AST-010', 'Temperature', 'TEMP_MOTOR', '2025-01-01 06:00:00', 148, 'F', 'Good', 'Normal', 180),
('TEL-021', 'AST-010', 'Temperature', 'TEMP_MOTOR', '2025-01-01 12:00:00', 162, 'F', 'Good', 'Normal', 180),
('TEL-022', 'AST-010', 'Temperature', 'TEMP_MOTOR', '2025-01-01 17:00:00', 168, 'F', 'Good', 'Warning', 180),
('TEL-023', 'AST-001', 'Temperature', 'TEMP_CHAMBER', '2025-01-01 06:00:00', 275, 'F', 'Good', 'Normal', 285),
('TEL-024', 'AST-001', 'Temperature', 'TEMP_CHAMBER', '2025-01-01 12:00:00', 274, 'F', 'Good', 'Normal', 285),
('TEL-025', 'AST-001', 'Pressure', 'PRESS_STEAM', '2025-01-01 06:00:00', 32, 'PSI', 'Good', 'Normal', 35),
('TEL-026', 'AST-001', 'Pressure', 'PRESS_STEAM', '2025-01-01 12:00:00', 31, 'PSI', 'Good', 'Normal', 35),
('TEL-027', 'AST-002', 'Temperature', 'TEMP_CHAMBER', '2025-01-01 08:00:00', 273, 'F', 'Good', 'Normal', 285),
('TEL-028', 'AST-002', 'Pressure', 'PRESS_STEAM', '2025-01-01 08:00:00', 30, 'PSI', 'Good', 'Normal', 35),
('TEL-029', 'AST-011', 'Temperature', 'TEMP_CHAMBER', '2025-01-01 09:00:00', 270, 'F', 'Good', 'Normal', 285),
('TEL-030', 'AST-011', 'Pressure', 'PRESS_STEAM', '2025-01-01 09:00:00', 29, 'PSI', 'Good', 'Normal', 35),
('TEL-031', 'AST-012', 'Temperature', 'TEMP_CHAMBER', '2025-01-01 10:00:00', 272, 'F', 'Good', 'Normal', 285),
('TEL-032', 'AST-012', 'Pressure', 'PRESS_STEAM', '2025-01-01 10:00:00', 30, 'PSI', 'Good', 'Normal', 35),
('TEL-033', 'AST-004', 'Temperature', 'TEMP_WATER', '2025-01-01 07:00:00', 180, 'F', 'Good', 'Normal', 185),
('TEL-034', 'AST-004', 'Temperature', 'TEMP_WATER', '2025-01-01 14:00:00', 181, 'F', 'Good', 'Normal', 185),
('TEL-035', 'AST-005', 'Temperature', 'TEMP_WATER', '2025-01-01 08:00:00', 179, 'F', 'Good', 'Normal', 185),
('TEL-036', 'AST-006', 'Temperature', 'TEMP_WATER', '2025-01-01 09:00:00', 180, 'F', 'Good', 'Normal', 185),
('TEL-037', 'AST-013', 'Temperature', 'TEMP_WATER', '2025-01-01 10:00:00', 178, 'F', 'Good', 'Normal', 185),
('TEL-038', 'AST-014', 'Temperature', 'TEMP_WATER', '2025-01-01 11:00:00', 179, 'F', 'Good', 'Normal', 185),
('TEL-039', 'AST-016', 'Vacuum', 'VAC_CHAMBER', '2025-01-01 08:00:00', 0.09, 'Torr', 'Good', 'Normal', 0.15),
('TEL-040', 'AST-016', 'H2O2_Concentration', 'H2O2_LEVEL', '2025-01-01 08:00:00', 1.82, 'mL', 'Good', 'Normal', 2.0),
('TEL-041', 'AST-017', 'Vacuum', 'VAC_CHAMBER', '2025-01-01 09:00:00', 0.08, 'Torr', 'Good', 'Normal', 0.15),
('TEL-042', 'AST-017', 'H2O2_Concentration', 'H2O2_LEVEL', '2025-01-01 09:00:00', 1.79, 'mL', 'Good', 'Normal', 2.0),
('TEL-043', 'AST-015', 'Vibration', 'VIB_CONVEYOR', '2025-01-01 10:00:00', 0.8, 'mm/s', 'Good', 'Normal', 2.5),
('TEL-044', 'AST-015', 'Temperature', 'TEMP_SEAL_BAR', '2025-01-01 10:00:00', 320, 'F', 'Good', 'Normal', 350),
('TEL-045', 'AST-009', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 08:00:00', 1.0, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-046', 'AST-009', 'Vibration', 'VIB_MAIN_DRIVE', '2025-01-01 14:00:00', 1.1, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-047', 'AST-018', 'Pressure', 'PRESS_AIR', '2025-01-01 06:00:00', 125, 'PSI', 'Good', 'Normal', 150),
('TEL-048', 'AST-018', 'Dewpoint', 'DEW_AIR', '2025-01-01 06:00:00', -38, 'F', 'Good', 'Normal', -35),
('TEL-049', 'AST-019', 'Temperature', 'TEMP_FLUE', '2025-01-01 07:00:00', 380, 'F', 'Good', 'Normal', 450),
('TEL-050', 'AST-019', 'Pressure', 'PRESS_STEAM_OUT', '2025-01-01 07:00:00', 85, 'PSI', 'Good', 'Normal', 100),
('TEL-051', 'AST-020', 'Temperature', 'TEMP_FLUE', '2025-01-01 08:00:00', 365, 'F', 'Good', 'Normal', 450),
('TEL-052', 'AST-020', 'Efficiency', 'EFF_COMBUSTION', '2025-01-01 08:00:00', 93.5, '%', 'Good', 'Normal', 90),
('TEL-053', 'AST-007', 'Temperature', 'TEMP_CHAMBER', '2025-01-01 11:00:00', 271, 'F', 'Good', 'Normal', 285),
('TEL-054', 'AST-007', 'Pressure', 'PRESS_STEAM', '2025-01-01 11:00:00', 28, 'PSI', 'Good', 'Normal', 35),
('TEL-055', 'AST-008', 'Temperature', 'TEMP_CHAMBER', '2025-01-01 12:00:00', 269, 'F', 'Good', 'Normal', 285),
('TEL-056', 'AST-008', 'Pressure', 'PRESS_STEAM', '2025-01-01 12:00:00', 29, 'PSI', 'Good', 'Normal', 35),
('TEL-057', 'AST-003', 'Temperature', 'TEMP_CHAMBER', '2025-01-01 13:00:00', 273, 'F', 'Good', 'Normal', 285),
('TEL-058', 'AST-003', 'Pressure', 'PRESS_STEAM', '2025-01-01 13:00:00', 31, 'PSI', 'Good', 'Normal', 35),
('TEL-059', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2024-12-31 00:00:00', 1.1, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-060', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2024-12-31 06:00:00', 1.0, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-061', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2024-12-31 12:00:00', 1.1, 'mm/s', 'Good', 'Normal', 3.5),
('TEL-062', 'AST-010', 'Vibration', 'VIB_MAIN_DRIVE', '2024-12-31 18:00:00', 1.2, 'mm/s', 'Good', 'Normal', 3.5);

-- ============================================================================
-- Table 5: Sepasoft MES Production Data
-- ============================================================================
CREATE OR REPLACE TABLE SEPASOFT_MES_PRODUCTION (
    PRODUCTION_ID VARCHAR(20) PRIMARY KEY,
    ASSET_ID VARCHAR(20) NOT NULL,
    PRODUCTION_DATE DATE NOT NULL,
    SHIFT VARCHAR(20),
    PRODUCT_TYPE VARCHAR(100),
    BATCH_NUMBER VARCHAR(50),
    UNITS_PRODUCED NUMBER(10,0),
    UNITS_TARGET NUMBER(10,0),
    UNITS_REJECTED NUMBER(10,0),
    QUALITY_STATUS VARCHAR(20),
    CYCLE_TIME_SECONDS NUMBER(10,0),
    OEE_AVAILABILITY NUMBER(5,2),
    OEE_PERFORMANCE NUMBER(5,2),
    OEE_QUALITY NUMBER(5,2),
    OEE_OVERALL NUMBER(5,2),
    DOWNTIME_MINUTES NUMBER(10,0),
    DOWNTIME_REASON VARCHAR(200)
)
COMMENT = 'Production data from Sepasoft MES including OEE metrics, quality status, and batch tracking';

COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.PRODUCTION_ID IS 'Unique identifier for each production record';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.ASSET_ID IS 'Reference to the production asset';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.PRODUCTION_DATE IS 'Date of production';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.SHIFT IS 'Production shift: Day or Night';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.PRODUCT_TYPE IS 'Type of product being produced';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.BATCH_NUMBER IS 'Batch/lot number for traceability';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.UNITS_PRODUCED IS 'Number of units produced';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.UNITS_TARGET IS 'Target production quantity';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.UNITS_REJECTED IS 'Number of units rejected for quality';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.QUALITY_STATUS IS 'Overall quality rating: Excellent, Good, Acceptable, or Poor';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.CYCLE_TIME_SECONDS IS 'Average cycle time in seconds';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.OEE_AVAILABILITY IS 'OEE Availability factor (0-1): Actual run time / Planned production time';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.OEE_PERFORMANCE IS 'OEE Performance factor (0-1): Actual output / Expected output at full speed';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.OEE_QUALITY IS 'OEE Quality factor (0-1): Good units / Total units produced';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.OEE_OVERALL IS 'Overall Equipment Effectiveness (Availability x Performance x Quality)';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.DOWNTIME_MINUTES IS 'Unplanned downtime in minutes';
COMMENT ON COLUMN SEPASOFT_MES_PRODUCTION.DOWNTIME_REASON IS 'Reason for downtime if applicable';

-- Insert Production Data
INSERT INTO SEPASOFT_MES_PRODUCTION (PRODUCTION_ID, ASSET_ID, PRODUCTION_DATE, SHIFT, PRODUCT_TYPE, BATCH_NUMBER, UNITS_PRODUCED, UNITS_TARGET, UNITS_REJECTED, QUALITY_STATUS, CYCLE_TIME_SECONDS, OEE_AVAILABILITY, OEE_PERFORMANCE, OEE_QUALITY, OEE_OVERALL, DOWNTIME_MINUTES, DOWNTIME_REASON) VALUES
('PROD-001', 'AST-010', '2025-01-01', 'Day', 'Sterile Packaging Type A', 'BATCH-2025-0001', 450, 500, 12, 'Acceptable', 45, 0.85, 0.90, 0.97, 0.74, 45, 'Vibration alarm investigation'),
('PROD-002', 'AST-010', '2025-01-01', 'Night', 'Sterile Packaging Type A', 'BATCH-2025-0002', 380, 500, 8, 'Acceptable', 48, 0.76, 0.76, 0.98, 0.57, 72, 'Equipment adjustment'),
('PROD-003', 'AST-015', '2025-01-01', 'Day', 'Sterile Packaging Type B', 'BATCH-2025-0003', 520, 500, 3, 'Excellent', 42, 0.98, 1.04, 0.99, 1.01, 6, 'Scheduled break'),
('PROD-004', 'AST-015', '2025-01-01', 'Night', 'Sterile Packaging Type B', 'BATCH-2025-0004', 495, 500, 5, 'Excellent', 43, 0.96, 0.99, 0.99, 0.94, 12, 'Material changeover'),
('PROD-005', 'AST-009', '2025-01-01', 'Day', 'Sterile Packaging Type A', 'BATCH-2025-0005', 485, 500, 7, 'Good', 44, 0.94, 0.97, 0.99, 0.90, 18, 'Minor adjustment'),
('PROD-006', 'AST-011', '2025-01-01', 'Day', 'Sterilization Cycle', 'BATCH-2025-0006', 24, 25, 0, 'Excellent', 3600, 0.96, 0.96, 1.00, 0.92, 15, 'Chamber prep'),
('PROD-007', 'AST-012', '2025-01-01', 'Day', 'Sterilization Cycle', 'BATCH-2025-0007', 23, 25, 0, 'Excellent', 3600, 0.92, 0.92, 1.00, 0.85, 30, 'Load arrangement'),
('PROD-008', 'AST-001', '2025-01-01', 'Day', 'Sterilization Cycle', 'BATCH-2025-0008', 20, 24, 1, 'Good', 3660, 0.88, 0.83, 0.95, 0.69, 45, 'Extended cycle time'),
('PROD-009', 'AST-002', '2025-01-01', 'Day', 'Sterilization Cycle', 'BATCH-2025-0009', 22, 24, 0, 'Excellent', 3600, 0.92, 0.92, 1.00, 0.85, 30, 'Normal operations'),
('PROD-010', 'AST-007', '2025-01-01', 'Day', 'Sterilization Cycle', 'BATCH-2025-0010', 18, 24, 2, 'Acceptable', 3720, 0.80, 0.75, 0.89, 0.53, 75, 'Door seal retry'),
('PROD-011', 'AST-013', '2025-01-01', 'Day', 'Wash-Disinfect Cycle', 'BATCH-2025-0011', 48, 50, 0, 'Excellent', 1800, 0.96, 0.96, 1.00, 0.92, 15, 'Rinse hold'),
('PROD-012', 'AST-014', '2025-01-01', 'Day', 'Wash-Disinfect Cycle', 'BATCH-2025-0012', 47, 50, 1, 'Good', 1800, 0.94, 0.94, 0.98, 0.87, 20, 'Filter check'),
('PROD-013', 'AST-004', '2025-01-01', 'Day', 'Wash-Disinfect Cycle', 'BATCH-2025-0013', 42, 50, 2, 'Acceptable', 1860, 0.88, 0.84, 0.95, 0.70, 40, 'Drain slow'),
('PROD-014', 'AST-016', '2025-01-01', 'Day', 'Low-Temp Sterilization', 'BATCH-2025-0014', 12, 12, 0, 'Excellent', 2700, 1.00, 1.00, 1.00, 1.00, 0, 'None'),
('PROD-015', 'AST-017', '2025-01-01', 'Day', 'Low-Temp Sterilization', 'BATCH-2025-0015', 11, 12, 0, 'Excellent', 2700, 0.95, 0.92, 1.00, 0.87, 18, 'Vaporizer warmup'),
('PROD-016', 'AST-010', '2024-12-31', 'Day', 'Sterile Packaging Type A', 'BATCH-2024-2890', 510, 500, 4, 'Excellent', 43, 0.98, 1.02, 0.99, 0.99, 6, 'None'),
('PROD-017', 'AST-010', '2024-12-31', 'Night', 'Sterile Packaging Type A', 'BATCH-2024-2891', 505, 500, 5, 'Excellent', 43, 0.97, 1.01, 0.99, 0.97, 9, 'None'),
('PROD-018', 'AST-010', '2024-12-30', 'Day', 'Sterile Packaging Type A', 'BATCH-2024-2888', 498, 500, 6, 'Excellent', 44, 0.96, 1.00, 0.99, 0.95, 12, 'None'),
('PROD-019', 'AST-010', '2024-12-30', 'Night', 'Sterile Packaging Type A', 'BATCH-2024-2889', 492, 500, 4, 'Excellent', 44, 0.95, 0.98, 0.99, 0.92, 15, 'None'),
('PROD-020', 'AST-015', '2024-12-31', 'Day', 'Sterile Packaging Type B', 'BATCH-2024-2892', 525, 500, 2, 'Excellent', 41, 0.99, 1.05, 1.00, 1.04, 3, 'None'),
('PROD-021', 'AST-015', '2024-12-31', 'Night', 'Sterile Packaging Type B', 'BATCH-2024-2893', 518, 500, 3, 'Excellent', 42, 0.98, 1.04, 0.99, 1.01, 6, 'None'),
('PROD-022', 'AST-011', '2024-12-31', 'Day', 'Sterilization Cycle', 'BATCH-2024-2894', 25, 25, 0, 'Excellent', 3600, 1.00, 1.00, 1.00, 1.00, 0, 'None'),
('PROD-023', 'AST-012', '2024-12-31', 'Day', 'Sterilization Cycle', 'BATCH-2024-2895', 24, 25, 0, 'Excellent', 3600, 0.96, 0.96, 1.00, 0.92, 15, 'None'),
('PROD-024', 'AST-001', '2024-12-15', 'Day', 'Sterilization Cycle', 'BATCH-2024-2750', 22, 24, 1, 'Good', 3630, 0.92, 0.92, 0.95, 0.81, 30, 'Valve adjustment'),
('PROD-025', 'AST-007', '2024-12-15', 'Day', 'Sterilization Cycle', 'BATCH-2024-2751', 19, 24, 1, 'Acceptable', 3700, 0.83, 0.79, 0.95, 0.62, 65, 'Gasket issue'),
('PROD-026', 'AST-009', '2024-12-31', 'Day', 'Sterile Packaging Type A', 'BATCH-2024-2896', 490, 500, 5, 'Excellent', 43, 0.95, 0.98, 0.99, 0.92, 15, 'None'),
('PROD-027', 'AST-009', '2024-12-31', 'Night', 'Sterile Packaging Type A', 'BATCH-2024-2897', 488, 500, 6, 'Good', 44, 0.94, 0.98, 0.99, 0.91, 18, 'None'),
('PROD-028', 'AST-013', '2024-12-31', 'Day', 'Wash-Disinfect Cycle', 'BATCH-2024-2898', 49, 50, 0, 'Excellent', 1800, 0.98, 0.98, 1.00, 0.96, 6, 'None'),
('PROD-029', 'AST-014', '2024-12-31', 'Day', 'Wash-Disinfect Cycle', 'BATCH-2024-2899', 48, 50, 0, 'Excellent', 1800, 0.96, 0.96, 1.00, 0.92, 12, 'None'),
('PROD-030', 'AST-016', '2024-12-31', 'Day', 'Low-Temp Sterilization', 'BATCH-2024-2900', 12, 12, 0, 'Excellent', 2700, 1.00, 1.00, 1.00, 1.00, 0, 'None'),
('PROD-031', 'AST-003', '2024-12-31', 'Day', 'Sterilization Cycle', 'BATCH-2024-2901', 23, 24, 0, 'Excellent', 3600, 0.96, 0.96, 1.00, 0.92, 15, 'None'),
('PROD-032', 'AST-008', '2024-12-31', 'Day', 'Sterilization Cycle', 'BATCH-2024-2902', 24, 25, 0, 'Excellent', 3600, 0.96, 0.96, 1.00, 0.92, 15, 'None'),
('PROD-033', 'AST-004', '2024-12-31', 'Day', 'Wash-Disinfect Cycle', 'BATCH-2024-2903', 45, 50, 1, 'Good', 1830, 0.92, 0.90, 0.98, 0.81, 25, 'None'),
('PROD-034', 'AST-005', '2024-12-31', 'Day', 'Wash-Disinfect Cycle', 'BATCH-2024-2904', 46, 50, 1, 'Good', 1820, 0.94, 0.92, 0.98, 0.85, 20, 'None'),
('PROD-035', 'AST-006', '2024-12-31', 'Day', 'Wash-Disinfect Cycle', 'BATCH-2024-2905', 48, 50, 0, 'Excellent', 1800, 0.96, 0.96, 1.00, 0.92, 12, 'None'),
('PROD-036', 'AST-010', '2024-11-15', 'Day', 'Sterile Packaging Type A', 'BATCH-2024-2500', 320, 500, 25, 'Poor', 52, 0.70, 0.64, 0.92, 0.41, 120, 'Wobbling - bracket realignment'),
('PROD-037', 'AST-010', '2024-08-10', 'Day', 'Sterile Packaging Type A', 'BATCH-2024-1800', 280, 500, 35, 'Poor', 55, 0.62, 0.56, 0.88, 0.31, 150, 'Wobbling issue - major repair'),
('PROD-038', 'AST-010', '2024-06-01', 'Day', 'Sterile Packaging Type A', 'BATCH-2024-1200', 350, 500, 20, 'Acceptable', 50, 0.75, 0.70, 0.94, 0.49, 100, 'Initial wobbling detected'),
('PROD-039', 'AST-007', '2024-11-01', 'Day', 'Sterilization Cycle', 'BATCH-2024-2450', 17, 24, 3, 'Poor', 3800, 0.75, 0.71, 0.82, 0.44, 90, 'Steam trap failure'),
('PROD-040', 'AST-019', '2024-10-05', 'Day', 'Utility-Steam', 'N/A', 100, 100, 0, 'Acceptable', NULL, 0.78, 1.00, 1.00, 0.78, 85, 'Efficiency degradation');

-- ============================================================================
-- Verify Data Loads
-- ============================================================================
SELECT 'EMAINT_ASSETS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM EMAINT_ASSETS
UNION ALL
SELECT 'EMAINT_WORK_ORDERS', COUNT(*) FROM EMAINT_WORK_ORDERS
UNION ALL
SELECT 'TECH_NOTES_UNSTRUCTURED', COUNT(*) FROM TECH_NOTES_UNSTRUCTURED
UNION ALL
SELECT 'IGNITION_SCADA_TELEMETRY', COUNT(*) FROM IGNITION_SCADA_TELEMETRY
UNION ALL
SELECT 'SEPASOFT_MES_PRODUCTION', COUNT(*) FROM SEPASOFT_MES_PRODUCTION;

SELECT 'Data insertion complete!' AS STATUS;
