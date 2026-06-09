# MFR Predictive Maintenance - Architecture

## Medallion Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                                                                 │
│                         Snowflake Snowpark ML Platform                          │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              ML & PREDICTIONS                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                 │
│  │  XGBoost        │  │  XGBoost        │  │  Isolation      │                 │
│  │  Regressor      │  │  Classifier     │  │  Forest         │                 │
│  │─────────────────│  │─────────────────│  │─────────────────│                 │
│  │ RUL Prediction  │  │ Failure Mode    │  │ Anomaly         │                 │
│  │ (days to fail)  │  │ Identification  │  │ Detection       │                 │
│  │                 │  │                 │  │                 │                 │
│  │ ✅ In Demo      │  │ ✅ In Demo      │  │ ✅ In Demo      │                 │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                 │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            FEATURE ENGINEERING                                  │
│  ┌───────────────────────┐  ┌───────────────────────┐  ┌─────────────────────┐  │
│  │   SCADA-Derived       │  │    CMMS-Derived        │  │   Composite         │  │
│  │───────────────────────│  │───────────────────────│  │─────────────────────│  │
│  │ • Rolling avg (7d,30d)│  │ • Cumulative WOs      │  │ • Asset age         │  │
│  │ • Trend % (vib,temp)  │  │ • Downtime hours      │  │ • Criticality       │  │
│  │ • Z-scores            │  │ • Avg MTTR            │  │ • Days since maint  │  │
│  │ • Daily stats         │  │ • Days since corrective│  │                    │  │
│  └───────────────────────┘  └───────────────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                RAW DATA                                         │
│  ┌───────────────────────┐  ┌───────────────────────┐  ┌─────────────────────┐  │
│  │    Ignition SCADA     │  │      eMaint CMMS      │  │   Failure Events    │  │
│  │───────────────────────│  │───────────────────────│  │─────────────────────│  │
│  │ • 175,200 readings    │  │ • Work Orders         │  │ • 19 labeled events │  │
│  │ • Vibration (mm/s)    │  │ • Asset Master (20)   │  │ • 4 failure types   │  │
│  │ • Motor Temp (°C)     │  │ • Component history   │  │ • Component mapping │  │
│  │ • Motor Current (A)   │  │ • Repair costs        │  │                     │  │
│  │ • Ambient Temp (°C)   │  │                       │  │                     │  │
│  └───────────────────────┘  └───────────────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## Component Mapping

| Layer | Component | Implementation | Status |
|-------|-----------|---------------|--------|
| **ML** | RUL Regression | `MFR_RUL_REGRESSOR` (XGBoost, 200 trees) | ✅ In Demo |
| **ML** | Failure Classification | `MFR_FAILURE_CLASSIFIER` (XGBoost, 4 classes) | ✅ In Demo |
| **ML** | Anomaly Detection | `MFR_ANOMALY_DETECTOR` (IsolationForest) | ✅ In Demo |
| **Features** | Training Features | `VW_ML_TRAINING_FEATURES` (7,300 rows, 24 features) | ✅ In Demo |
| **Features** | Labeled Dataset | `VW_ML_LABELED_DATASET` (1,261 balanced samples) | ✅ In Demo |
| **Raw** | SCADA Telemetry | `SENSOR_READINGS_GENERATED` (175,200 hourly readings) | ✅ In Demo |
| **Raw** | Asset Registry | `ASSET_MASTER` (20 assets) | ✅ In Demo |
| **Raw** | Failure History | `FAILURE_EVENTS` (19 labeled failures) | ✅ In Demo |

---

## Data Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Ignition   │     │    eMaint    │     │   Failure    │
│    SCADA     │     │    CMMS      │     │   Labels     │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────┐
│               RAW Schema (Bronze Layer)                  │
│  SENSOR_READINGS_GENERATED │ ASSET_MASTER │ FAILURE_EVENTS│
└─────────────────────────────┬───────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│             FEATURES Schema (Silver Layer)               │
│    VW_ML_TRAINING_FEATURES  │  VW_ML_LABELED_DATASET    │
│    Rolling stats, trends, z-scores, CMMS metrics        │
└─────────────────────────────┬───────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│               ML Schema (Gold Layer)                     │
│    Model Registry: 3 registered models                   │
│    COMPONENT_RUL_PREDICTIONS │ PREDICTION_EVIDENCE       │
│    FEATURE_IMPORTANCE_RESULTS │ MODEL_PREDICTIONS        │
└─────────────────────────────────────────────────────────┘
```

---

## ML Pipeline Details

### XGBoost RUL Regressor

Predicts continuous **days to failure** for each asset.

- **Algorithm**: XGBoost Regressor (reg:squarederror)
- **Hyperparameters**: 200 trees, max_depth=6, lr=0.05, subsample=0.8
- **Input**: 24 SCADA + CMMS features
- **Output**: Predicted days until next failure
- **Registered as**: `MFR_RUL_REGRESSOR`

### XGBoost Failure Mode Classifier

Identifies **which component will fail** across 4 failure modes.

- **Algorithm**: XGBoost Classifier (multi:softprob)
- **Hyperparameters**: 200 trees, max_depth=5, lr=0.05
- **Classes**: BEARING_WEAR, BRACKET_LOOSE, MOTOR_OVERLOAD, ELECTRICAL_FAULT
- **Component Mapping**:
  - BEARING_WEAR -> Motor Bearing
  - BRACKET_LOOSE -> Mounting Bracket
  - MOTOR_OVERLOAD -> Drive Motor
  - ELECTRICAL_FAULT -> Control Board
- **Registered as**: `MFR_FAILURE_CLASSIFIER`

### Isolation Forest Anomaly Detector

Detects **abnormal sensor patterns** that deviate from normal operation.

- **Algorithm**: IsolationForest (unsupervised)
- **Registered as**: `MFR_ANOMALY_DETECTOR`

---

## Feature Engineering (24 Features)

| Category | Features | Source |
|----------|----------|--------|
| **Daily Sensor Stats** | vibration avg/max/min/std, motor temp avg/max, current avg/max | SCADA |
| **Rolling Averages** | vibration 7d avg, 7d max, 30d avg | SCADA |
| **Trend Indicators** | vibration trend 7d/30d, temp trend 7d, current trend 7d | SCADA |
| **Anomaly Signals** | vibration z-score, temp z-score | SCADA |
| **Asset Context** | asset age days, days since last maintenance, criticality score | CMMS + Master |
| **CMMS History** | cumulative corrective WOs, cumulative downtime hrs, avg MTTR, days since last corrective | CMMS |
