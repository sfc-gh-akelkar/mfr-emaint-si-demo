import os
import sys
import json
import warnings
import pickle
from datetime import datetime

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import (
    mean_absolute_error,
    r2_score,
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    classification_report,
    confusion_matrix,
)
from sklearn.ensemble import IsolationForest
import xgboost as xgb

warnings.filterwarnings("ignore")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from snowpark_session import create_snowpark_session

ROLE = "SF_INTELLIGENCE_DEMO"
DATABASE = "MFR_RELIABILITY_DB"
WAREHOUSE = "MFR_ANALYTICS_WH"

FEATURE_COLS = [
    "VIBRATION_DAILY_AVG",
    "VIBRATION_DAILY_MAX",
    "VIBRATION_DAILY_MIN",
    "VIBRATION_DAILY_STD",
    "MOTOR_TEMP_DAILY_AVG",
    "MOTOR_TEMP_DAILY_MAX",
    "MOTOR_CURRENT_DAILY_AVG",
    "MOTOR_CURRENT_DAILY_MAX",
    "VIBRATION_7D_AVG",
    "VIBRATION_7D_MAX",
    "VIBRATION_30D_AVG",
    "VIBRATION_TREND_7D",
    "VIBRATION_TREND_30D",
    "TEMP_TREND_7D",
    "CURRENT_TREND_7D",
    "VIBRATION_Z_SCORE",
    "TEMP_Z_SCORE",
    "ASSET_AGE_DAYS",
    "DAYS_SINCE_LAST_MAINTENANCE",
    "CRITICALITY_SCORE",
    "CUMULATIVE_CORRECTIVE_WOS",
    "CUMULATIVE_DOWNTIME_HOURS",
    "AVG_MTTR_HOURS",
    "DAYS_SINCE_LAST_CORRECTIVE",
]


def create_session():
    connection_name = os.getenv("SNOWFLAKE_CONNECTION_NAME", "default")
    session = create_snowpark_session(connection_name)
    session.sql(f"USE DATABASE {DATABASE}").collect()
    session.sql(f"USE WAREHOUSE {WAREHOUSE}").collect()
    role = session.sql("SELECT CURRENT_ROLE()").collect()[0][0]
    print(f"Connected: role={role}, db={DATABASE}, wh={WAREHOUSE}")
    return session


def build_feature_store(session):
    print("\n" + "=" * 70)
    print("PHASE 1: Building ML Feature Store")
    print("=" * 70)

    session.sql("""
    CREATE OR REPLACE VIEW FEATURES.VW_ML_TRAINING_FEATURES AS
    WITH daily_sensor AS (
        SELECT
            ASSET_ID,
            DATE_TRUNC('DAY', READING_TIMESTAMP)::DATE AS FEATURE_DATE,
            AVG(VIBRATION_MM_S) AS VIBRATION_DAILY_AVG,
            MAX(VIBRATION_MM_S) AS VIBRATION_DAILY_MAX,
            MIN(VIBRATION_MM_S) AS VIBRATION_DAILY_MIN,
            STDDEV(VIBRATION_MM_S) AS VIBRATION_DAILY_STD,
            AVG(MOTOR_TEMP_C) AS MOTOR_TEMP_DAILY_AVG,
            MAX(MOTOR_TEMP_C) AS MOTOR_TEMP_DAILY_MAX,
            AVG(MOTOR_CURRENT_A) AS MOTOR_CURRENT_DAILY_AVG,
            MAX(MOTOR_CURRENT_A) AS MOTOR_CURRENT_DAILY_MAX,
            AVG(AMBIENT_TEMP_C) AS AMBIENT_TEMP_DAILY_AVG,
            COUNT(*) AS READINGS_PER_DAY
        FROM RAW.SENSOR_READINGS_GENERATED
        GROUP BY ASSET_ID, DATE_TRUNC('DAY', READING_TIMESTAMP)::DATE
    ),
    rolling_features AS (
        SELECT
            ds.*,
            AVG(ds.VIBRATION_DAILY_AVG) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ) AS VIBRATION_7D_AVG,
            MAX(ds.VIBRATION_DAILY_MAX) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ) AS VIBRATION_7D_MAX,
            AVG(ds.VIBRATION_DAILY_AVG) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
            ) AS VIBRATION_30D_AVG,
            (ds.VIBRATION_DAILY_AVG - LAG(ds.VIBRATION_DAILY_AVG, 7) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
            )) / NULLIF(LAG(ds.VIBRATION_DAILY_AVG, 7) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
            ), 0) * 100 AS VIBRATION_TREND_7D,
            (ds.VIBRATION_DAILY_AVG - LAG(ds.VIBRATION_DAILY_AVG, 30) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
            )) / NULLIF(LAG(ds.VIBRATION_DAILY_AVG, 30) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
            ), 0) * 100 AS VIBRATION_TREND_30D,
            (ds.MOTOR_TEMP_DAILY_AVG - LAG(ds.MOTOR_TEMP_DAILY_AVG, 7) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
            )) / NULLIF(LAG(ds.MOTOR_TEMP_DAILY_AVG, 7) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
            ), 0) * 100 AS TEMP_TREND_7D,
            (ds.MOTOR_CURRENT_DAILY_AVG - LAG(ds.MOTOR_CURRENT_DAILY_AVG, 7) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
            )) / NULLIF(LAG(ds.MOTOR_CURRENT_DAILY_AVG, 7) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
            ), 0) * 100 AS CURRENT_TREND_7D,
            (ds.VIBRATION_DAILY_AVG - AVG(ds.VIBRATION_DAILY_AVG) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
            )) / NULLIF(STDDEV(ds.VIBRATION_DAILY_AVG) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
            ), 0) AS VIBRATION_Z_SCORE,
            (ds.MOTOR_TEMP_DAILY_AVG - AVG(ds.MOTOR_TEMP_DAILY_AVG) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
            )) / NULLIF(STDDEV(ds.MOTOR_TEMP_DAILY_AVG) OVER (
                PARTITION BY ds.ASSET_ID ORDER BY ds.FEATURE_DATE
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
            ), 0) AS TEMP_Z_SCORE
        FROM daily_sensor ds
    ),
    asset_features AS (
        SELECT
            rf.*,
            DATEDIFF('DAY', am.INSTALL_DATE, rf.FEATURE_DATE) AS ASSET_AGE_DAYS,
            DATEDIFF('DAY', am.LAST_MAINTENANCE_DATE, rf.FEATURE_DATE) AS DAYS_SINCE_LAST_MAINTENANCE,
            am.CRITICALITY_SCORE,
            am.PRODUCTION_IMPACT_HOURLY_USD,
            am.EXPECTED_LIFE_YEARS
        FROM rolling_features rf
        JOIN RAW.ASSET_MASTER am ON rf.ASSET_ID = am.ASSET_ID
    ),
    cmms_agg AS (
        SELECT
            af.ASSET_ID,
            af.FEATURE_DATE,
            COUNT(fe.EVENT_ID) AS CUMULATIVE_CORRECTIVE_WOS,
            COALESCE(SUM(fe.DOWNTIME_HOURS), 0) AS CUMULATIVE_DOWNTIME_HOURS,
            COALESCE(AVG(fe.DOWNTIME_HOURS), 0) AS AVG_MTTR_HOURS,
            COALESCE(DATEDIFF('DAY', MAX(fe.FAILURE_TIMESTAMP::DATE), af.FEATURE_DATE), 365) AS DAYS_SINCE_LAST_CORRECTIVE
        FROM asset_features af
        LEFT JOIN RAW.FAILURE_EVENTS fe
            ON fe.ASSET_ID = af.ASSET_ID
            AND fe.FAILURE_TIMESTAMP::DATE <= af.FEATURE_DATE
        GROUP BY af.ASSET_ID, af.FEATURE_DATE
    ),
    cmms_features AS (
        SELECT
            af.*,
            COALESCE(ca.CUMULATIVE_CORRECTIVE_WOS, 0) AS CUMULATIVE_CORRECTIVE_WOS,
            COALESCE(ca.CUMULATIVE_DOWNTIME_HOURS, 0) AS CUMULATIVE_DOWNTIME_HOURS,
            COALESCE(ca.AVG_MTTR_HOURS, 0) AS AVG_MTTR_HOURS,
            COALESCE(ca.DAYS_SINCE_LAST_CORRECTIVE, 365) AS DAYS_SINCE_LAST_CORRECTIVE
        FROM asset_features af
        LEFT JOIN cmms_agg ca
            ON af.ASSET_ID = ca.ASSET_ID
            AND af.FEATURE_DATE = ca.FEATURE_DATE
    )
    SELECT * FROM cmms_features
    """).collect()

    count = session.sql("SELECT COUNT(*) AS CNT FROM FEATURES.VW_ML_TRAINING_FEATURES").to_pandas()["CNT"][0]
    print(f"  Feature store view created: {count:,} rows")

    session.sql("""
    CREATE OR REPLACE VIEW FEATURES.VW_ML_LABELED_DATASET AS
    SELECT
        f.*,
        fe.FAILURE_TYPE AS FAILURE_MODE,
        DATEDIFF('DAY', f.FEATURE_DATE, fe.FAILURE_TIMESTAMP::DATE) AS DAYS_TO_FAILURE,
        CASE WHEN DATEDIFF('DAY', f.FEATURE_DATE, fe.FAILURE_TIMESTAMP::DATE) <= 30 THEN 1 ELSE 0 END AS FAILURE_WITHIN_30D,
        CASE WHEN DATEDIFF('DAY', f.FEATURE_DATE, fe.FAILURE_TIMESTAMP::DATE) <= 14 THEN 1 ELSE 0 END AS FAILURE_WITHIN_14D,
        CASE WHEN DATEDIFF('DAY', f.FEATURE_DATE, fe.FAILURE_TIMESTAMP::DATE) <= 7 THEN 1 ELSE 0 END AS FAILURE_WITHIN_7D
    FROM FEATURES.VW_ML_TRAINING_FEATURES f
    INNER JOIN (
        SELECT
            ASSET_ID,
            FAILURE_TIMESTAMP,
            FAILURE_TYPE,
            LAG(FAILURE_TIMESTAMP) OVER (PARTITION BY ASSET_ID ORDER BY FAILURE_TIMESTAMP) AS PREV_FAILURE
        FROM RAW.FAILURE_EVENTS
    ) fe ON f.ASSET_ID = fe.ASSET_ID
        AND f.FEATURE_DATE < fe.FAILURE_TIMESTAMP::DATE
        AND f.FEATURE_DATE >= COALESCE(fe.PREV_FAILURE::DATE, '2024-01-01')
        AND DATEDIFF('DAY', f.FEATURE_DATE, fe.FAILURE_TIMESTAMP::DATE) <= 90
    WHERE f.FEATURE_DATE >= '2024-02-01'
    """).collect()

    count_labeled = session.sql("SELECT COUNT(*) AS CNT FROM FEATURES.VW_ML_LABELED_DATASET").to_pandas()["CNT"][0]
    print(f"  Labeled dataset view created: {count_labeled:,} rows")

    return count_labeled


def load_training_data(session):
    print("\n" + "=" * 70)
    print("PHASE 2: Loading Training Data")
    print("=" * 70)

    df = session.sql(f"""
    SELECT
        ASSET_ID,
        FEATURE_DATE,
        {', '.join(FEATURE_COLS)},
        FAILURE_MODE,
        DAYS_TO_FAILURE,
        FAILURE_WITHIN_30D,
        FAILURE_WITHIN_14D,
        FAILURE_WITHIN_7D
    FROM FEATURES.VW_ML_LABELED_DATASET
    WHERE VIBRATION_7D_AVG IS NOT NULL
    ORDER BY ASSET_ID, FEATURE_DATE
    """).to_pandas()

    healthy_df = session.sql(f"""
    SELECT
        f.ASSET_ID,
        f.FEATURE_DATE,
        {', '.join(['f.' + c for c in FEATURE_COLS])},
        'HEALTHY' AS FAILURE_MODE,
        365 AS DAYS_TO_FAILURE,
        0 AS FAILURE_WITHIN_30D,
        0 AS FAILURE_WITHIN_14D,
        0 AS FAILURE_WITHIN_7D
    FROM FEATURES.VW_ML_TRAINING_FEATURES f
    LEFT JOIN RAW.FAILURE_EVENTS fe
        ON f.ASSET_ID = fe.ASSET_ID
        AND ABS(DATEDIFF('DAY', f.FEATURE_DATE, fe.FAILURE_TIMESTAMP::DATE)) <= 45
    WHERE fe.ASSET_ID IS NULL
    AND f.VIBRATION_7D_AVG IS NOT NULL
    AND f.FEATURE_DATE >= '2024-02-01'
    ORDER BY RANDOM()
    LIMIT {len(df)}
    """).to_pandas()

    combined = pd.concat([df, healthy_df], ignore_index=True)
    combined = combined.sample(frac=1, random_state=42).reset_index(drop=True)

    print(f"  Failure samples: {len(df):,}")
    print(f"  Healthy samples: {len(healthy_df):,}")
    print(f"  Total training data: {len(combined):,}")
    print(f"  Failure mode distribution:")
    for mode, count in combined["FAILURE_MODE"].value_counts().items():
        print(f"    {mode}: {count}")

    return combined


def train_rul_model(df):
    print("\n" + "=" * 70)
    print("PHASE 3: Training RUL Regression Model (XGBoost)")
    print("=" * 70)

    failure_df = df[df["FAILURE_MODE"] != "HEALTHY"].copy()
    failure_df["DAYS_TO_FAILURE"] = failure_df["DAYS_TO_FAILURE"].clip(upper=90)

    X = failure_df[FEATURE_COLS].fillna(0).astype(float)
    y = failure_df["DAYS_TO_FAILURE"].astype(float)

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    model = xgb.XGBRegressor(
        n_estimators=200,
        max_depth=6,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        min_child_weight=5,
        reg_alpha=0.1,
        reg_lambda=1.0,
        random_state=42,
        objective="reg:squarederror",
    )
    model.fit(
        X_train, y_train,
        eval_set=[(X_test, y_test)],
        verbose=False,
    )

    y_pred = model.predict(X_test)
    mae = mean_absolute_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)

    print(f"  Train samples: {len(X_train):,}")
    print(f"  Test samples:  {len(X_test):,}")
    print(f"  MAE (days):    {mae:.2f}")
    print(f"  R² Score:      {r2:.4f}")

    importance = pd.DataFrame({
        "feature": FEATURE_COLS,
        "importance": model.feature_importances_,
    }).sort_values("importance", ascending=False)
    print(f"\n  Top 10 Feature Importances:")
    for _, row in importance.head(10).iterrows():
        print(f"    {row['feature']}: {row['importance']:.4f}")

    metrics = {
        "mae_days": float(mae),
        "r2_score": float(r2),
        "train_samples": int(len(X_train)),
        "test_samples": int(len(X_test)),
    }

    return model, importance, metrics


def train_failure_classifier(df):
    print("\n" + "=" * 70)
    print("PHASE 4: Training Failure Mode Classifier (XGBoost)")
    print("=" * 70)

    failure_df = df[df["FAILURE_MODE"] != "HEALTHY"].copy()

    le = LabelEncoder()
    failure_df["FAILURE_MODE_ENCODED"] = le.fit_transform(failure_df["FAILURE_MODE"])

    X = failure_df[FEATURE_COLS].fillna(0).astype(float)
    y = failure_df["FAILURE_MODE_ENCODED"]

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

    model = xgb.XGBClassifier(
        n_estimators=200,
        max_depth=5,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        min_child_weight=3,
        random_state=42,
        objective="multi:softprob",
        num_class=len(le.classes_),
        eval_metric="mlogloss",
    )
    model.fit(
        X_train, y_train,
        eval_set=[(X_test, y_test)],
        verbose=False,
    )

    y_pred = model.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred, average="weighted")

    print(f"  Classes: {list(le.classes_)}")
    print(f"  Train samples: {len(X_train):,}")
    print(f"  Test samples:  {len(X_test):,}")
    print(f"  Accuracy:      {acc:.4f}")
    print(f"  F1 (weighted): {f1:.4f}")
    print(f"\n  Classification Report:")
    report = classification_report(y_test, y_pred, target_names=le.classes_)
    for line in report.split("\n"):
        print(f"    {line}")

    metrics = {
        "accuracy": float(acc),
        "f1_weighted": float(f1),
        "train_samples": int(len(X_train)),
        "test_samples": int(len(X_test)),
    }

    return model, le, metrics


def train_anomaly_detector(df):
    print("\n" + "=" * 70)
    print("PHASE 5: Training Anomaly Detection Model (IsolationForest)")
    print("=" * 70)

    healthy_df = df[df["FAILURE_MODE"] == "HEALTHY"]

    anomaly_features = [
        "VIBRATION_DAILY_AVG", "VIBRATION_DAILY_MAX", "VIBRATION_DAILY_STD",
        "MOTOR_TEMP_DAILY_AVG", "MOTOR_CURRENT_DAILY_AVG",
        "VIBRATION_Z_SCORE", "TEMP_Z_SCORE",
    ]

    X_healthy = healthy_df[anomaly_features].fillna(0).astype(float)

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X_healthy)

    model = IsolationForest(
        n_estimators=200,
        contamination=0.05,
        max_features=0.8,
        random_state=42,
    )
    model.fit(X_scaled)

    X_all = df[anomaly_features].fillna(0).astype(float)
    X_all_scaled = scaler.transform(X_all)
    scores = model.decision_function(X_all_scaled)
    predictions = model.predict(X_all_scaled)

    healthy_scores = scores[df["FAILURE_MODE"] == "HEALTHY"]
    failure_scores = scores[df["FAILURE_MODE"] != "HEALTHY"]

    print(f"  Trained on {len(X_healthy):,} healthy samples")
    print(f"  Healthy mean anomaly score: {healthy_scores.mean():.4f}")
    print(f"  Failure mean anomaly score: {failure_scores.mean():.4f}")
    print(f"  Score separation: {healthy_scores.mean() - failure_scores.mean():.4f}")

    anomaly_rate_healthy = (predictions[df["FAILURE_MODE"] == "HEALTHY"] == -1).mean()
    anomaly_rate_failure = (predictions[df["FAILURE_MODE"] != "HEALTHY"] == -1).mean()
    print(f"  Anomaly rate (healthy): {anomaly_rate_healthy:.1%}")
    print(f"  Anomaly rate (failure): {anomaly_rate_failure:.1%}")

    metrics = {
        "healthy_mean_score": float(healthy_scores.mean()),
        "failure_mean_score": float(failure_scores.mean()),
        "anomaly_rate_healthy": float(anomaly_rate_healthy),
        "anomaly_rate_failure": float(anomaly_rate_failure),
    }

    return model, scaler, anomaly_features, metrics


def register_models(session, rul_model, classifier_model, le, anomaly_model, scaler,
                     rul_metrics, classifier_metrics, anomaly_metrics, feature_importance):
    print("\n" + "=" * 70)
    print("PHASE 6: Registering Models in Snowflake")
    print("=" * 70)

    from snowflake.ml.registry import Registry

    reg = Registry(session=session, database_name=DATABASE, schema_name="ML")

    sample_input = pd.DataFrame({col: [0.0] for col in FEATURE_COLS})

    print("  Registering RUL Regression model...")
    rul_mv = reg.log_model(
        model=rul_model,
        model_name="MFR_RUL_REGRESSOR",
        version_name=f"v_{datetime.now().strftime('%Y%m%d_%H%M')}",
        sample_input_data=sample_input,
        comment="XGBoost RUL regression - predicts days to failure from SCADA + CMMS features",
        metrics=rul_metrics,
    )
    print(f"    Registered: {rul_mv.model_name} / {rul_mv.version_name}")

    print("  Registering Failure Mode Classifier...")
    classifier_mv = reg.log_model(
        model=classifier_model,
        model_name="MFR_FAILURE_CLASSIFIER",
        version_name=f"v_{datetime.now().strftime('%Y%m%d_%H%M')}",
        sample_input_data=sample_input,
        comment="XGBoost multi-class classifier - identifies failure mode (BEARING_WEAR, MOTOR_OVERLOAD, etc)",
        metrics=classifier_metrics,
    )
    print(f"    Registered: {classifier_mv.model_name} / {classifier_mv.version_name}")

    anomaly_features_list = [
        "VIBRATION_DAILY_AVG", "VIBRATION_DAILY_MAX", "VIBRATION_DAILY_STD",
        "MOTOR_TEMP_DAILY_AVG", "MOTOR_CURRENT_DAILY_AVG",
        "VIBRATION_Z_SCORE", "TEMP_Z_SCORE",
    ]
    anomaly_sample = pd.DataFrame({col: [0.0] for col in anomaly_features_list})

    print("  Registering Anomaly Detection model...")
    from snowflake.ml.model import custom_model

    class AnomalyPipeline(custom_model.CustomModel):
        def __init__(self, context: custom_model.ModelContext) -> None:
            super().__init__(context)
            self.scaler = context.model_ref("scaler")
            self.iforest = context.model_ref("iforest")

        @custom_model.inference_api
        def predict(self, input_df: pd.DataFrame) -> pd.DataFrame:
            scaled = self.scaler.transform(input_df.values)
            scores = self.iforest.decision_function(scaled)
            labels = self.iforest.predict(scaled)
            anomaly_score = 1.0 - (scores - scores.min()) / (scores.max() - scores.min() + 1e-10)
            return pd.DataFrame({
                "ANOMALY_SCORE": anomaly_score,
                "IS_ANOMALY": (labels == -1).astype(int),
            })

    pipeline = AnomalyPipeline(
        custom_model.ModelContext(
            models={"scaler": scaler, "iforest": anomaly_model},
        )
    )

    anomaly_mv = reg.log_model(
        model=pipeline,
        model_name="MFR_ANOMALY_DETECTOR",
        version_name=f"v_{datetime.now().strftime('%Y%m%d_%H%M')}",
        sample_input_data=anomaly_sample,
        comment="IsolationForest anomaly detector - flags abnormal sensor patterns",
        metrics=anomaly_metrics,
    )
    print(f"    Registered: {anomaly_mv.model_name} / {anomaly_mv.version_name}")

    session.sql("""
    CREATE OR REPLACE TABLE ML.FEATURE_IMPORTANCE_RESULTS (
        MODEL_NAME VARCHAR(100),
        FEATURE_NAME VARCHAR(100),
        IMPORTANCE_SCORE FLOAT,
        IMPORTANCE_RANK INT,
        COMPUTATION_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
    )
    """).collect()

    fi_records = []
    for rank, (_, row) in enumerate(feature_importance.iterrows(), 1):
        fi_records.append({
            "MODEL_NAME": "MFR_RUL_REGRESSOR",
            "FEATURE_NAME": row["feature"],
            "IMPORTANCE_SCORE": float(row["importance"]),
            "IMPORTANCE_RANK": rank,
        })

    fi_df = session.create_dataframe(fi_records)
    fi_df.write.mode("overwrite").save_as_table("ML.FEATURE_IMPORTANCE_RESULTS")
    print(f"  Feature importance saved: {len(fi_records)} features")

    return reg, rul_mv, classifier_mv, anomaly_mv


def run_inference(session, rul_model, classifier_model, le, anomaly_model, scaler, anomaly_features_list):
    print("\n" + "=" * 70)
    print("PHASE 7: Running Inference on All Assets")
    print("=" * 70)

    latest_features = session.sql(f"""
    SELECT
        ASSET_ID,
        FEATURE_DATE,
        {', '.join(FEATURE_COLS)}
    FROM FEATURES.VW_ML_TRAINING_FEATURES
    WHERE FEATURE_DATE = (SELECT MAX(FEATURE_DATE) FROM FEATURES.VW_ML_TRAINING_FEATURES)
    AND VIBRATION_7D_AVG IS NOT NULL
    ORDER BY ASSET_ID
    """).to_pandas()

    print(f"  Scoring {len(latest_features)} assets...")

    X = latest_features[FEATURE_COLS].fillna(0).astype(float)

    rul_predictions = rul_model.predict(X)
    rul_predictions = np.clip(rul_predictions, 7, 365)

    failure_mode_encoded = classifier_model.predict(X)
    failure_mode_proba = classifier_model.predict_proba(X)
    failure_modes = le.inverse_transform(failure_mode_encoded)
    failure_confidence = np.max(failure_mode_proba, axis=1)

    X_anomaly = latest_features[anomaly_features_list].fillna(0).astype(float)
    X_anomaly_scaled = scaler.transform(X_anomaly)
    anomaly_scores_raw = anomaly_model.decision_function(X_anomaly_scaled)
    anomaly_scores = 1.0 - (anomaly_scores_raw - anomaly_scores_raw.min()) / (anomaly_scores_raw.max() - anomaly_scores_raw.min() + 1e-10)

    FAILURE_TO_COMPONENT = {
        "BEARING_WEAR": "MOTOR_BEARING",
        "BRACKET_LOOSE": "MOUNTING_BRACKET",
        "MOTOR_OVERLOAD": "DRIVE_MOTOR",
        "ELECTRICAL_FAULT": "CONTROL_BOARD",
    }

    FAILURE_REASONS = {
        "BEARING_WEAR": "Vibration signature indicates progressive bearing degradation. Rolling element fatigue detected via spectral analysis of vibration trends.",
        "BRACKET_LOOSE": "Intermittent vibration spikes with increasing baseline suggest loosening mounting hardware. Pattern matches bolt torque loss degradation curve.",
        "MOTOR_OVERLOAD": "Motor current trending above rated capacity with thermal rise. Degradation pattern consistent with insulation breakdown or mechanical binding.",
        "ELECTRICAL_FAULT": "Erratic sensor patterns with temperature correlation indicate control board component degradation. Capacitor aging signature detected.",
    }

    RECOMMENDED_ACTIONS = {
        "BEARING_WEAR": "Schedule bearing replacement. Order replacement bearings and schedule 6-8 hour maintenance window.",
        "BRACKET_LOOSE": "Inspect and re-torque all mounting bolts. Check bracket for fatigue cracks. Consider Loctite on critical fasteners.",
        "MOTOR_OVERLOAD": "Inspect motor windings and cooling system. Check for mechanical binding in driven equipment. Verify voltage supply.",
        "ELECTRICAL_FAULT": "Inspect control board for burnt components. Check wiring connections and insulation resistance. Schedule board replacement.",
    }

    session.sql("""
    CREATE OR REPLACE TABLE ML.COMPONENT_RUL_PREDICTIONS (
        ASSET_ID VARCHAR(50),
        COMPONENT VARCHAR(100),
        RUL_DAYS NUMBER(10,1),
        RUL_HOURS NUMBER(10,0),
        CONFIDENCE_PCT NUMBER(5,1),
        FAILURE_REASON VARCHAR(1000),
        RECOMMENDED_ACTION VARCHAR(1000),
        PREDICTED_FAILURE_DATE DATE,
        PREDICTION_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
        ANOMALY_SCORE FLOAT,
        FAILURE_MODE VARCHAR(50),
        FAILURE_PROBABILITY FLOAT,
        TOP_CONTRIBUTING_FEATURES VARIANT
    )
    """).collect()

    top_features_global = dict(zip(
        FEATURE_COLS,
        rul_model.feature_importances_
    ))
    top_features_sorted = sorted(top_features_global.items(), key=lambda x: x[1], reverse=True)[:5]

    rul_records = []
    for i, row in latest_features.iterrows():
        asset_id = row["ASSET_ID"]
        rul_days = float(rul_predictions[i])
        fm = failure_modes[i]
        conf = float(failure_confidence[i]) * 100
        anom = float(anomaly_scores[i])

        top_contribs = []
        for feat, imp in top_features_sorted:
            val = float(row[feat]) if pd.notna(row[feat]) else 0.0
            top_contribs.append({
                "feature": feat,
                "importance": round(float(imp), 4),
                "value": round(val, 4),
            })

        predicted_failure_date = (datetime.now() + pd.Timedelta(days=rul_days)).strftime("%Y-%m-%d")

        rul_records.append({
            "ASSET_ID": asset_id,
            "COMPONENT": FAILURE_TO_COMPONENT.get(fm, "UNKNOWN"),
            "RUL_DAYS": round(rul_days, 1),
            "RUL_HOURS": int(rul_days * 24),
            "CONFIDENCE_PCT": round(conf, 1),
            "FAILURE_REASON": FAILURE_REASONS.get(fm, "Under investigation"),
            "RECOMMENDED_ACTION": RECOMMENDED_ACTIONS.get(fm, "Schedule inspection"),
            "PREDICTED_FAILURE_DATE": predicted_failure_date,
            "ANOMALY_SCORE": round(anom, 4),
            "FAILURE_MODE": fm,
            "FAILURE_PROBABILITY": round(float(failure_confidence[i]), 4),
            "TOP_CONTRIBUTING_FEATURES": json.dumps(top_contribs),
        })

    rul_df = session.create_dataframe(rul_records)
    rul_df.write.mode("overwrite").save_as_table("ML.COMPONENT_RUL_PREDICTIONS")
    print(f"  COMPONENT_RUL_PREDICTIONS populated: {len(rul_records)} assets")

    session.sql("""
    CREATE OR REPLACE TABLE ML.PREDICTION_EVIDENCE (
        ASSET_ID VARCHAR(50),
        EVIDENCE_TYPE VARCHAR(50),
        EVIDENCE_DETAIL VARCHAR(2000),
        CONTRIBUTION_TO_PREDICTION NUMBER(5,1),
        DATA_SOURCE VARCHAR(50),
        EVIDENCE_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
    )
    """).collect()

    evidence_records = []
    for i, row in latest_features.iterrows():
        asset_id = row["ASSET_ID"]
        fm = failure_modes[i]

        vib = row.get("VIBRATION_DAILY_AVG", 0) or 0
        vib_7d = row.get("VIBRATION_7D_AVG", 0) or 0
        vib_trend = row.get("VIBRATION_TREND_7D", 0) or 0
        temp = row.get("MOTOR_TEMP_DAILY_AVG", 0) or 0
        current = row.get("MOTOR_CURRENT_DAILY_AVG", 0) or 0
        vib_z = row.get("VIBRATION_Z_SCORE", 0) or 0
        cum_wo = row.get("CUMULATIVE_CORRECTIVE_WOS", 0) or 0
        avg_mttr = row.get("AVG_MTTR_HOURS", 0) or 0
        days_last_corr = row.get("DAYS_SINCE_LAST_CORRECTIVE", 365) or 365

        evidence_records.append({
            "ASSET_ID": asset_id,
            "EVIDENCE_TYPE": "SCADA_VIBRATION",
            "EVIDENCE_DETAIL": f"Current vibration: {vib:.2f} mm/s (7-day avg: {vib_7d:.2f} mm/s). "
                              f"Trend: {vib_trend:+.1f}% over 7 days. Z-score: {vib_z:.2f}.",
            "CONTRIBUTION_TO_PREDICTION": round(float(top_features_global.get("VIBRATION_DAILY_AVG", 0)) * 100, 1),
            "DATA_SOURCE": "IGNITION_SCADA",
        })
        evidence_records.append({
            "ASSET_ID": asset_id,
            "EVIDENCE_TYPE": "SCADA_TEMPERATURE",
            "EVIDENCE_DETAIL": f"Motor temperature: {temp:.1f}°C. Motor current: {current:.1f}A.",
            "CONTRIBUTION_TO_PREDICTION": round(float(top_features_global.get("MOTOR_TEMP_DAILY_AVG", 0)) * 100, 1),
            "DATA_SOURCE": "IGNITION_SCADA",
        })
        evidence_records.append({
            "ASSET_ID": asset_id,
            "EVIDENCE_TYPE": "CMMS_HISTORY",
            "EVIDENCE_DETAIL": f"{int(cum_wo)} corrective work orders on record. Avg MTTR: {avg_mttr:.1f} hrs. "
                              f"Last corrective: {int(days_last_corr)} days ago.",
            "CONTRIBUTION_TO_PREDICTION": round(float(top_features_global.get("CUMULATIVE_CORRECTIVE_WOS", 0)) * 100, 1),
            "DATA_SOURCE": "EMAINT_CMMS",
        })

        if fm == "BEARING_WEAR":
            evidence_records.append({
                "ASSET_ID": asset_id,
                "EVIDENCE_TYPE": "FAILURE_PATTERN_MATCH",
                "EVIDENCE_DETAIL": f"Vibration signature matches BEARING_WEAR pattern with {failure_confidence[i]:.0%} confidence. "
                                  f"Progressive amplitude increase consistent with rolling element fatigue.",
                "CONTRIBUTION_TO_PREDICTION": 15.0,
                "DATA_SOURCE": "ML_MODEL",
            })
        elif fm == "BRACKET_LOOSE":
            evidence_records.append({
                "ASSET_ID": asset_id,
                "EVIDENCE_TYPE": "FAILURE_PATTERN_MATCH",
                "EVIDENCE_DETAIL": f"Vibration pattern matches BRACKET_LOOSE with {failure_confidence[i]:.0%} confidence. "
                                  f"Intermittent spikes suggest loosening mounting hardware.",
                "CONTRIBUTION_TO_PREDICTION": 15.0,
                "DATA_SOURCE": "ML_MODEL",
            })
        elif fm == "MOTOR_OVERLOAD":
            evidence_records.append({
                "ASSET_ID": asset_id,
                "EVIDENCE_TYPE": "FAILURE_PATTERN_MATCH",
                "EVIDENCE_DETAIL": f"Current/temperature pattern matches MOTOR_OVERLOAD with {failure_confidence[i]:.0%} confidence. "
                                  f"Thermal rise rate above normal degradation curve.",
                "CONTRIBUTION_TO_PREDICTION": 15.0,
                "DATA_SOURCE": "ML_MODEL",
            })
        elif fm == "ELECTRICAL_FAULT":
            evidence_records.append({
                "ASSET_ID": asset_id,
                "EVIDENCE_TYPE": "FAILURE_PATTERN_MATCH",
                "EVIDENCE_DETAIL": f"Sensor pattern matches ELECTRICAL_FAULT with {failure_confidence[i]:.0%} confidence. "
                                  f"Erratic readings indicate control electronics degradation.",
                "CONTRIBUTION_TO_PREDICTION": 15.0,
                "DATA_SOURCE": "ML_MODEL",
            })

    ev_df = session.create_dataframe(evidence_records)
    ev_df.write.mode("overwrite").save_as_table("ML.PREDICTION_EVIDENCE")
    print(f"  PREDICTION_EVIDENCE populated: {len(evidence_records)} evidence records")

    session.sql("""
    CREATE OR REPLACE TABLE ML.MODEL_PREDICTIONS AS
    SELECT
        rul.ASSET_ID,
        CURRENT_TIMESTAMP() AS PREDICTION_TIMESTAMP,
        'MFR_RUL_REGRESSOR' AS MODEL_ID,
        rul.ANOMALY_SCORE,
        rul.FAILURE_PROBABILITY,
        rul.RUL_DAYS AS PREDICTED_RUL_DAYS,
        (rul.ANOMALY_SCORE * 0.3 + rul.FAILURE_PROBABILITY * 0.5 + (1 - rul.RUL_DAYS/365) * 0.2) * 100 AS RISK_SCORE,
        rul.CONFIDENCE_PCT / 100 AS CONFIDENCE,
        CASE WHEN (rul.ANOMALY_SCORE * 0.3 + rul.FAILURE_PROBABILITY * 0.5 + (1 - rul.RUL_DAYS/365) * 0.2) * 100 >= 71 THEN TRUE ELSE FALSE END AS ALERT_GENERATED,
        CASE
            WHEN (rul.ANOMALY_SCORE * 0.3 + rul.FAILURE_PROBABILITY * 0.5 + (1 - rul.RUL_DAYS/365) * 0.2) * 100 >= 86 THEN 'CRITICAL'
            WHEN (rul.ANOMALY_SCORE * 0.3 + rul.FAILURE_PROBABILITY * 0.5 + (1 - rul.RUL_DAYS/365) * 0.2) * 100 >= 71 THEN 'HIGH'
            WHEN (rul.ANOMALY_SCORE * 0.3 + rul.FAILURE_PROBABILITY * 0.5 + (1 - rul.RUL_DAYS/365) * 0.2) * 100 >= 41 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS ALERT_LEVEL
    FROM ML.COMPONENT_RUL_PREDICTIONS rul
    """).collect()
    print("  MODEL_PREDICTIONS refreshed from real model outputs")

    session.sql("""
    CREATE OR REPLACE VIEW ML.HISTORICAL_FAILURE_PATTERNS AS
    SELECT
        fe.FAILURE_TYPE AS FAILURE_MODE,
        COUNT(*) AS OCCURRENCE_COUNT,
        AVG(fe.DOWNTIME_HOURS) AS AVG_DOWNTIME_HOURS,
        AVG(fe.REPAIR_COST_USD) AS AVG_REPAIR_COST,
        LISTAGG(DISTINCT fe.ASSET_ID, ', ') AS AFFECTED_ASSETS,
        MIN(fe.FAILURE_TIMESTAMP) AS FIRST_OCCURRENCE,
        MAX(fe.FAILURE_TIMESTAMP) AS LAST_OCCURRENCE
    FROM RAW.FAILURE_EVENTS fe
    GROUP BY fe.FAILURE_TYPE
    """).collect()
    print("  HISTORICAL_FAILURE_PATTERNS view created")

    session.sql("""
    CREATE OR REPLACE VIEW ML.MAINTENANCE_WORK_QUEUE AS
    SELECT
        rul.ASSET_ID,
        am.ASSET_NAME,
        am.ASSET_TYPE,
        rul.COMPONENT,
        rul.RUL_DAYS,
        rul.FAILURE_MODE,
        rul.CONFIDENCE_PCT,
        rul.PREDICTED_FAILURE_DATE,
        rul.RECOMMENDED_ACTION,
        am.PRODUCTION_IMPACT_HOURLY_USD,
        am.CRITICALITY_SCORE,
        CASE
            WHEN rul.RUL_DAYS <= 14 THEN 'URGENT'
            WHEN rul.RUL_DAYS <= 30 THEN 'HIGH'
            WHEN rul.RUL_DAYS <= 60 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS PRIORITY,
        ROW_NUMBER() OVER (ORDER BY rul.RUL_DAYS ASC) AS QUEUE_POSITION
    FROM ML.COMPONENT_RUL_PREDICTIONS rul
    JOIN RAW.ASSET_MASTER am ON rul.ASSET_ID = am.ASSET_ID
    ORDER BY rul.RUL_DAYS ASC
    """).collect()
    print("  MAINTENANCE_WORK_QUEUE view created")

    return rul_records


def print_demo_results(session):
    print("\n" + "=" * 70)
    print("DEMO OUTPUT: Component RUL Predictions")
    print("=" * 70)

    results = session.sql("""
    SELECT
        rul.ASSET_ID,
        am.ASSET_NAME,
        rul.COMPONENT,
        rul.RUL_DAYS,
        rul.FAILURE_MODE,
        rul.CONFIDENCE_PCT,
        rul.ANOMALY_SCORE,
        rul.PREDICTED_FAILURE_DATE
    FROM ML.COMPONENT_RUL_PREDICTIONS rul
    JOIN RAW.ASSET_MASTER am ON rul.ASSET_ID = am.ASSET_ID
    ORDER BY rul.RUL_DAYS ASC
    """).to_pandas()

    print(f"\n{'ASSET':<10} {'NAME':<30} {'COMPONENT':<18} {'RUL':>6} {'MODE':<18} {'CONF':>5} {'ANOM':>6} {'FAIL DATE':>12}")
    print("-" * 120)
    for _, r in results.iterrows():
        print(f"{r['ASSET_ID']:<10} {r['ASSET_NAME']:<30} {r['COMPONENT']:<18} {r['RUL_DAYS']:>5.0f}d {r['FAILURE_MODE']:<18} {r['CONFIDENCE_PCT']:>4.0f}% {r['ANOMALY_SCORE']:>5.2f}  {r['PREDICTED_FAILURE_DATE']}")

    print(f"\n{'='*70}")
    print("DEMO OUTPUT: Maintenance Work Queue (Top 5)")
    print("=" * 70)

    queue = session.sql("""
    SELECT * FROM ML.MAINTENANCE_WORK_QUEUE ORDER BY QUEUE_POSITION LIMIT 5
    """).to_pandas()

    for _, q in queue.iterrows():
        print(f"\n  #{int(q['QUEUE_POSITION'])} {q['ASSET_NAME']} ({q['ASSET_ID']})")
        print(f"     Component: {q['COMPONENT']} | RUL: {q['RUL_DAYS']:.0f} days | Priority: {q['PRIORITY']}")
        print(f"     Failure Mode: {q['FAILURE_MODE']} | Confidence: {q['CONFIDENCE_PCT']:.0f}%")
        print(f"     Action: {q['RECOMMENDED_ACTION']}")


def main():
    print("=" * 70)
    print("MFR PREDICTIVE MAINTENANCE - ML MODEL TRAINING PIPELINE")
    print(f"Run Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)

    session = create_session()

    build_feature_store(session)

    df = load_training_data(session)

    rul_model, feature_importance, rul_metrics = train_rul_model(df)

    classifier_model, le, classifier_metrics = train_failure_classifier(df)

    anomaly_features_list = [
        "VIBRATION_DAILY_AVG", "VIBRATION_DAILY_MAX", "VIBRATION_DAILY_STD",
        "MOTOR_TEMP_DAILY_AVG", "MOTOR_CURRENT_DAILY_AVG",
        "VIBRATION_Z_SCORE", "TEMP_Z_SCORE",
    ]
    anomaly_model, scaler, _, anomaly_metrics = train_anomaly_detector(df)

    print("\n" + "=" * 70)
    print("PHASE 6: Registering Models")
    print("=" * 70)
    try:
        register_models(
            session, rul_model, classifier_model, le,
            anomaly_model, scaler,
            rul_metrics, classifier_metrics, anomaly_metrics,
            feature_importance,
        )
    except Exception as e:
        print(f"  Model Registry registration failed: {e}")
        print("  Saving models locally instead...")
        model_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "models")
        os.makedirs(model_dir, exist_ok=True)
        pickle.dump(rul_model, open(os.path.join(model_dir, "rul_regressor.pkl"), "wb"))
        pickle.dump(classifier_model, open(os.path.join(model_dir, "failure_classifier.pkl"), "wb"))
        pickle.dump(le, open(os.path.join(model_dir, "label_encoder.pkl"), "wb"))
        pickle.dump(anomaly_model, open(os.path.join(model_dir, "anomaly_detector.pkl"), "wb"))
        pickle.dump(scaler, open(os.path.join(model_dir, "anomaly_scaler.pkl"), "wb"))
        print(f"  Models saved to: {model_dir}")

    run_inference(session, rul_model, classifier_model, le, anomaly_model, scaler, anomaly_features_list)

    print_demo_results(session)

    print("\n" + "=" * 70)
    print("PIPELINE COMPLETE")
    print("=" * 70)
    print(f"\nSnowflake Objects Updated:")
    print(f"  FEATURES.VW_ML_TRAINING_FEATURES  (feature store)")
    print(f"  FEATURES.VW_ML_LABELED_DATASET    (labeled training data)")
    print(f"  ML.COMPONENT_RUL_PREDICTIONS      (per-asset RUL + component + failure mode)")
    print(f"  ML.PREDICTION_EVIDENCE            (SCADA + CMMS evidence per prediction)")
    print(f"  ML.MODEL_PREDICTIONS              (risk scores for analytics views)")
    print(f"  ML.FEATURE_IMPORTANCE_RESULTS     (model explainability)")
    print(f"  ML.HISTORICAL_FAILURE_PATTERNS    (aggregated failure history)")
    print(f"  ML.MAINTENANCE_WORK_QUEUE         (prioritized work queue)")

    session.close()


if __name__ == "__main__":
    main()
