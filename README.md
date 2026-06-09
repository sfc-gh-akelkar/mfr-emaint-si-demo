# MFR Predictive Maintenance & RUL Platform

## Overview

This demo showcases **Snowflake's native ML capabilities** for MFR's asset reliability program. Using Snowpark ML, XGBoost, and the Snowflake Model Registry, we build predictive models that tell maintenance teams **when** equipment will fail, **what** component will fail, and **why** — directly from SCADA telemetry and CMMS work order history.

**Audience**: Reliability Engineering & IT Operations Leadership

## Business Context

This demo targets a manufacturing facility that generates rich data from SCADA sensors and eMaint CMMS, but today that data is used reactively. This platform transforms it into **proactive, component-level failure predictions**.

| Challenge | Solution |
|-----------|----------|
| Reactive maintenance | XGBoost regression predicts RUL in days |
| "Which machine is at risk?" | Multi-class classifier identifies the failing component |
| Black-box risk scores | Feature importance shows exactly why each prediction was made |
| Disconnected data silos | SCADA + CMMS features fused in a single ML pipeline |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                                         │
│  ┌─────────────────────────┐     ┌─────────────────────────┐               │
│  │    Ignition SCADA       │     │      eMaint CMMS        │               │
│  │  Vibration (mm/s)       │     │  Work Orders            │               │
│  │  Motor Temperature (°C) │     │  Failure Events         │               │
│  │  Motor Current (A)      │     │  Component Replacements │               │
│  │  Ambient Temp (°C)      │     │  Repair Times & Costs   │               │
│  │  Cycle Count            │     │                         │               │
│  └────────────┬────────────┘     └────────────┬────────────┘               │
└───────────────┼────────────────────────────────┼───────────────────────────┘
                │              RAW SCHEMA         │
                ▼                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      FEATURE ENGINEERING (FEATURES Schema)                  │
│                                                                             │
│  Rolling Averages (7d, 30d)  │  Trend % (vibration, temp, current)         │
│  Z-Scores (anomaly signals)  │  CMMS: cumulative WOs, downtime, MTTR      │
│  Asset age, criticality      │  Days since last corrective maintenance     │
│                                                                             │
│  VW_ML_TRAINING_FEATURES (7,300 rows)                                      │
│  VW_ML_LABELED_DATASET (1,261 labeled samples)                             │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      ML MODELS (ML Schema + Model Registry)                 │
│                                                                             │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────┐  │
│  │  XGBoost Regressor   │  │  XGBoost Classifier  │  │  IsolationForest │  │
│  │  MFR_RUL_REGRESSOR│  │  MFR_FAILURE_     │  │  MFR_ANOMALY_ │  │
│  │                      │  │  CLASSIFIER          │  │  DETECTOR        │  │
│  │  Predicts: RUL in    │  │  Predicts: Failure   │  │  Detects: Sensor │  │
│  │  days until failure   │  │  mode (BEARING_WEAR, │  │  anomalies from  │  │
│  │                      │  │  BRACKET_LOOSE,      │  │  normal operating│  │
│  │                      │  │  MOTOR_OVERLOAD,     │  │  patterns        │  │
│  │                      │  │  ELECTRICAL_FAULT)   │  │                  │  │
│  └──────────────────────┘  └──────────────────────┘  └──────────────────┘  │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      PREDICTIONS & EVIDENCE (ML Schema)                     │
│                                                                             │
│  COMPONENT_RUL_PREDICTIONS  │  PREDICTION_EVIDENCE  │  FEATURE_IMPORTANCE  │
│  "AST-010 Motor Bearing:    │  SCADA + CMMS signals │  Top 24 features     │
│   12 days RUL, 87% conf"   │  driving prediction   │  ranked by impact    │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

1. Snowflake account with Snowpark ML enabled (Enterprise edition or higher)
2. A role with permissions to create databases, schemas, tables, views, and models
3. A warehouse (X-Small or larger is sufficient for this demo dataset)
4. Python 3.9+ with dependencies from `requirements.txt`

### Customization

The SQL scripts and Python code reference the following objects — update them to match your environment:

| Object | Default Value | Where Referenced |
|--------|--------------|------------------|
| Role | `SF_INTELLIGENCE_DEMO` | All SQL scripts, `train_predictive_models.py` |
| Warehouse | `MFR_ANALYTICS_WH` | `sql/20_infrastructure_setup.sql` |
| Database | `MFR_RELIABILITY_DB` | All scripts |

To adapt: find-and-replace these values in the `sql/` and `scripts/` directories with your own role, warehouse, and database names.

### Setup (Run SQL scripts in order)

| Step | Script | Description |
|------|--------|-------------|
| 1 | `sql/01_setup_database.sql` | Create database, schemas, and warehouse |
| 2 | `sql/02_create_raw_tables.sql` | Create tables and insert all demo data |
| 3 | `sql/03_create_curated_views.sql` | Create feature engineering views |

```bash
cd sql
snowsql -f 01_setup_database.sql
snowsql -f 02_create_raw_tables.sql
snowsql -f 03_create_curated_views.sql
```

### Run the Demo

Open **`demo_notebook.ipynb`** in Snowsight. This single notebook walks through the entire pipeline:

1. Source data exploration (SCADA telemetry + CMMS work orders)
2. Data quality validation (null rates, outlier detection, reading frequency)
3. Feature engineering (rolling stats, trends, z-scores, CMMS metrics)
4. Model training (XGBoost regressor + classifier + anomaly detector)
5. Fleet-wide predictions with component-level RUL and failure mode ID

## Demo Data Summary

| Table | Records | Description |
|-------|---------|-------------|
| RAW.ASSET_MASTER | 20 | Equipment master data (sterilizers, washers, packaging) |
| RAW.SENSOR_READINGS_GENERATED | 175,200 | SCADA telemetry (Jan-Dec 2024), hourly readings |
| RAW.FAILURE_EVENTS | 19 | Historical failures across 4 failure modes |
| FEATURES.VW_ML_TRAINING_FEATURES | 7,300 | Engineered features combining SCADA + CMMS |
| FEATURES.VW_ML_LABELED_DATASET | 1,261 | Labeled training samples (balanced across failure types) |

### Failure Mode Distribution

| Failure Type | Count | Mapped Component |
|-------------|-------|-----------------|
| BEARING_WEAR | 681 | Motor Bearing |
| BRACKET_LOOSE | 246 | Mounting Bracket |
| MOTOR_OVERLOAD | 247 | Drive Motor |
| ELECTRICAL_FAULT | 87 | Control Board |

## ML Models

All models are registered in the **Snowflake Model Registry** under the ML schema:

| Model | Type | Algorithm | Purpose |
|-------|------|-----------|---------|
| `MFR_RUL_REGRESSOR` | Regression | XGBoost | Predict days until failure |
| `MFR_FAILURE_CLASSIFIER` | Multi-class | XGBoost | Identify failure mode + component |
| `MFR_ANOMALY_DETECTOR` | Unsupervised | IsolationForest | Detect abnormal sensor patterns |

### Key Features (24 total)

- **SCADA Sensors**: vibration, motor temp, motor current (daily avg/max/min/std)
- **Rolling Statistics**: 7-day and 30-day averages and maximums
- **Trend Indicators**: vibration/temp/current trend percentages (7d, 30d)
- **Anomaly Signals**: vibration and temperature z-scores
- **CMMS History**: cumulative corrective WOs, downtime hours, avg MTTR, days since last corrective
- **Asset Context**: asset age, days since last maintenance, criticality score

## File Structure

```
mfr-emaint-demo/
├── README.md                              # This file
├── ARCHITECTURE.md                        # Technical architecture details
├── demo_notebook.ipynb                    # Primary demo notebook (Snowsight)
├── data/
│   ├── scada_telemetry_ml.csv             # SCADA sensor training data
│   ├── work_orders_ml.csv                 # CMMS work order training data
│   └── failure_labels_ml.csv              # Failure event labels
├── scripts/
│   ├── generate_ml_training_data.py       # Generate synthetic training data
│   ├── train_predictive_models.py         # Standalone model training script
│   └── snowpark_session.py                # Snowpark session management
├── sql/
│   ├── 01_setup_database.sql              # Database & schema creation
│   ├── 02_create_raw_tables.sql           # Tables + INSERT statements
│   ├── 03_create_curated_views.sql        # Feature engineering views
│   └── 20_infrastructure_setup.sql        # Warehouse & role setup
└── streamlit/
    └── app.py                             # Streamlit dashboard (optional)
```

## Technical References

| Resource | URL | Used For |
|----------|-----|----------|
| **Snowpark ML Model Registry** | https://docs.snowflake.com/en/developer-guide/snowpark-ml/model-registry/overview | Registering XGBoost models |
| **Snowflake Notebooks** | https://docs.snowflake.com/en/user-guide/ui-snowsight/notebooks | Running demo_notebook.ipynb |
| **XGBoost Documentation** | https://xgboost.readthedocs.io/ | Regressor & classifier parameters |

### Role Requirements

The role you use must have:
- `USAGE` on the database and warehouse
- `CREATE TABLE`, `CREATE VIEW` on relevant schemas
- `CREATE MODEL` on the ML schema
- `USAGE` on the `SNOWFLAKE.ML` application package (for Model Registry)

---

**Built with Snowflake Snowpark ML** | Licensed under Apache 2.0
