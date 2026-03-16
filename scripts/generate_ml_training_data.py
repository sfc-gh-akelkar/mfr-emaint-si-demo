#!/usr/bin/env python3
"""
STERIS Predictive Maintenance ML Demo - Synthetic Data Generator

Generates realistic training data for RUL prediction and failure classification:
- Extended SCADA telemetry with physics-based degradation patterns
- Historical work orders with diverse failure modes
- Labeled failure events for supervised learning

Data Requirements:
- 15,000+ SCADA telemetry readings (540 days × 20 assets)
- 120+ work orders (50 corrective, 70 preventive)
- 350+ labeled training observations (50 failures × 5 time horizons + healthy)

Usage:
    python scripts/generate_ml_training_data.py
    
    # Or execute directly in Snowflake notebook
"""

import random
import math
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import Literal

import numpy as np

RANDOM_SEED = 42
random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)

START_DATE = datetime(2024, 1, 1)
END_DATE = datetime(2025, 1, 15)
TOTAL_DAYS = (END_DATE - START_DATE).days

FAILURE_MODES = ["BEARING_WEAR", "BRACKET_LOOSE", "MOTOR_OVERLOAD", "ELECTRICAL_FAULT"]

FAILURE_MODE_DISTRIBUTION = {
    "BEARING_WEAR": 0.30,
    "BRACKET_LOOSE": 0.24,
    "MOTOR_OVERLOAD": 0.26,
    "ELECTRICAL_FAULT": 0.20,
}

FAILURE_MODE_CHARACTERISTICS = {
    "BEARING_WEAR": {
        "vibration_base": 1.2,
        "vibration_growth_rate": 0.03,
        "vibration_noise": 0.1,
        "temp_correlation": 0.3,
        "temp_base": 22.0,
        "typical_duration_days": (60, 90),
    },
    "BRACKET_LOOSE": {
        "vibration_base": 1.3,
        "vibration_growth_rate": 0.02,
        "vibration_noise": 0.35,
        "vibration_spike_prob": 0.15,
        "temp_correlation": 0.1,
        "temp_base": 22.0,
        "typical_duration_days": (45, 75),
    },
    "MOTOR_OVERLOAD": {
        "vibration_base": 1.1,
        "vibration_growth_rate": 0.015,
        "vibration_noise": 0.15,
        "temp_correlation": 0.7,
        "temp_base": 23.0,
        "temp_growth_rate": 0.08,
        "typical_duration_days": (30, 60),
    },
    "ELECTRICAL_FAULT": {
        "vibration_base": 1.0,
        "vibration_growth_rate": 0.01,
        "vibration_noise": 0.25,
        "temp_correlation": 0.4,
        "temp_base": 22.5,
        "erratic_prob": 0.2,
        "typical_duration_days": (20, 45),
    },
}

ASSETS = [f"AST-{str(i).zfill(3)}" for i in range(1, 21)]

ASSET_FAILURE_PROPENSITY = {
    "AST-001": 1.2,
    "AST-002": 0.8,
    "AST-003": 1.0,
    "AST-004": 1.4,
    "AST-005": 1.0,
    "AST-006": 0.6,
    "AST-007": 1.6,
    "AST-008": 0.8,
    "AST-009": 1.2,
    "AST-010": 1.8,
    "AST-011": 0.4,
    "AST-012": 0.4,
    "AST-013": 0.5,
    "AST-014": 0.5,
    "AST-015": 0.6,
    "AST-016": 0.6,
    "AST-017": 0.4,
    "AST-018": 1.0,
    "AST-019": 1.2,
    "AST-020": 0.4,
}


@dataclass
class FailureEvent:
    asset_id: str
    failure_date: datetime
    failure_mode: str
    cycle_start_date: datetime
    cycle_duration_days: int


@dataclass
class TelemetryReading:
    telemetry_id: str
    asset_id: str
    sensor_type: str
    sensor_name: str
    reading_timestamp: datetime
    reading_value: float
    unit: str
    reading_quality: str
    alarm_status: str
    alarm_threshold: float


@dataclass
class WorkOrder:
    wo_id: str
    asset_id: str
    wo_type: str
    work_description: str
    failure_code: str
    root_cause: str
    priority: str
    status: str
    created_date: datetime
    scheduled_date: datetime
    completed_date: datetime
    technician: str
    labor_hours: float
    parts_cost: float
    labor_cost: float
    total_repair_cost: float
    mttr_hours: float
    downtime_hours: float


@dataclass
class FailureLabel:
    label_id: str
    asset_id: str
    observation_date: datetime
    actual_failure_date: datetime
    days_to_failure: int
    failure_mode: str
    is_failure_imminent: bool


def select_failure_mode() -> str:
    r = random.random()
    cumulative = 0.0
    for mode, prob in FAILURE_MODE_DISTRIBUTION.items():
        cumulative += prob
        if r <= cumulative:
            return mode
    return "BEARING_WEAR"


def calculate_vibration(
    days_to_failure: int, failure_mode: str, time_of_day_hour: int = 12
) -> float:
    chars = FAILURE_MODE_CHARACTERISTICS[failure_mode]
    base = chars["vibration_base"]
    growth_rate = chars["vibration_growth_rate"]
    noise_std = chars["vibration_noise"]

    if days_to_failure <= 0:
        days_to_failure = 1

    degradation = base * math.exp((90 - days_to_failure) * growth_rate)
    noise = np.random.normal(0, noise_std)

    if failure_mode == "BRACKET_LOOSE":
        spike_prob = chars.get("vibration_spike_prob", 0.1)
        if random.random() < spike_prob and days_to_failure < 30:
            degradation += random.uniform(0.5, 1.5)

    if failure_mode == "ELECTRICAL_FAULT":
        erratic_prob = chars.get("erratic_prob", 0.15)
        if random.random() < erratic_prob:
            degradation *= random.uniform(0.8, 1.4)

    shift_factor = 1.0 + 0.05 * math.sin(2 * math.pi * time_of_day_hour / 24)
    result = degradation * shift_factor + noise

    return max(0.5, min(6.0, result))


def calculate_temperature(
    days_to_failure: int,
    failure_mode: str,
    vibration: float,
    ambient: float = 22.0,
) -> float:
    chars = FAILURE_MODE_CHARACTERISTICS[failure_mode]
    temp_correlation = chars["temp_correlation"]
    temp_base = chars.get("temp_base", 22.0)

    heat_from_vibration = (vibration - 1.2) * 2.0 * temp_correlation

    if failure_mode == "MOTOR_OVERLOAD":
        temp_growth = chars.get("temp_growth_rate", 0.05)
        heat_factor = (90 - days_to_failure) * temp_growth
        noise = np.random.normal(0, 0.5)
    else:
        heat_factor = (90 - days_to_failure) * 0.02
        noise = np.random.normal(0, 0.3)

    result = temp_base + heat_from_vibration + heat_factor + noise
    return max(18.0, min(45.0, result))


def generate_failure_events() -> list[FailureEvent]:
    events = []
    target_failures = 55

    for asset_id in ASSETS:
        propensity = ASSET_FAILURE_PROPENSITY.get(asset_id, 0.5)
        expected_failures = int(propensity * 3) + 1

        current_date = START_DATE + timedelta(days=random.randint(30, 90))

        for _ in range(expected_failures):
            if current_date >= END_DATE - timedelta(days=30):
                break

            failure_mode = select_failure_mode()
            chars = FAILURE_MODE_CHARACTERISTICS[failure_mode]
            duration_min, duration_max = chars["typical_duration_days"]
            cycle_duration = random.randint(duration_min, duration_max)

            failure_date = current_date + timedelta(days=cycle_duration)

            if failure_date < END_DATE:
                events.append(
                    FailureEvent(
                        asset_id=asset_id,
                        failure_date=failure_date,
                        failure_mode=failure_mode,
                        cycle_start_date=current_date,
                        cycle_duration_days=cycle_duration,
                    )
                )

            repair_time = random.randint(1, 3)
            current_date = failure_date + timedelta(days=repair_time + random.randint(20, 45))

    events.append(
        FailureEvent(
            asset_id="AST-010",
            failure_date=datetime(2024, 6, 1),
            failure_mode="BRACKET_LOOSE",
            cycle_start_date=datetime(2024, 4, 1),
            cycle_duration_days=61,
        )
    )
    events.append(
        FailureEvent(
            asset_id="AST-010",
            failure_date=datetime(2024, 8, 10),
            failure_mode="BRACKET_LOOSE",
            cycle_start_date=datetime(2024, 6, 5),
            cycle_duration_days=66,
        )
    )
    events.append(
        FailureEvent(
            asset_id="AST-010",
            failure_date=datetime(2024, 10, 15),
            failure_mode="BRACKET_LOOSE",
            cycle_start_date=datetime(2024, 8, 15),
            cycle_duration_days=61,
        )
    )
    events.append(
        FailureEvent(
            asset_id="AST-010",
            failure_date=datetime(2025, 1, 15),
            failure_mode="BRACKET_LOOSE",
            cycle_start_date=datetime(2024, 11, 1),
            cycle_duration_days=75,
        )
    )

    return events


def generate_telemetry(failure_events: list[FailureEvent]) -> list[TelemetryReading]:
    readings = []
    telemetry_id = 1000

    failure_lookup = {}
    for event in failure_events:
        if event.asset_id not in failure_lookup:
            failure_lookup[event.asset_id] = []
        failure_lookup[event.asset_id].append(event)

    for asset_id in ASSETS:
        asset_events = sorted(
            failure_lookup.get(asset_id, []), key=lambda e: e.failure_date
        )

        current_date = START_DATE
        readings_per_day = 4

        while current_date < END_DATE:
            active_event = None
            for event in asset_events:
                if event.cycle_start_date <= current_date <= event.failure_date:
                    active_event = event
                    break

            for hour in [6, 12, 18, 23]:
                timestamp = current_date.replace(hour=hour, minute=0, second=0)

                if active_event:
                    days_to_failure = (active_event.failure_date - current_date).days
                    failure_mode = active_event.failure_mode
                else:
                    days_to_failure = 999
                    failure_mode = "BEARING_WEAR"

                vibration = calculate_vibration(days_to_failure, failure_mode, hour)
                temperature = calculate_temperature(
                    days_to_failure, failure_mode, vibration
                )

                if vibration > 3.5:
                    alarm_status = "Critical"
                elif vibration > 2.5:
                    alarm_status = "High"
                elif vibration > 2.0:
                    alarm_status = "Warning"
                else:
                    alarm_status = "Normal"

                readings.append(
                    TelemetryReading(
                        telemetry_id=f"TEL-{telemetry_id:06d}",
                        asset_id=asset_id,
                        sensor_type="Vibration",
                        sensor_name="VIB_MAIN_DRIVE",
                        reading_timestamp=timestamp,
                        reading_value=round(vibration, 2),
                        unit="mm/s",
                        reading_quality="Good",
                        alarm_status=alarm_status,
                        alarm_threshold=3.5,
                    )
                )
                telemetry_id += 1

                if hour in [6, 18]:
                    if temperature > 35:
                        temp_alarm = "Warning"
                    else:
                        temp_alarm = "Normal"

                    readings.append(
                        TelemetryReading(
                            telemetry_id=f"TEL-{telemetry_id:06d}",
                            asset_id=asset_id,
                            sensor_type="Temperature",
                            sensor_name="TEMP_AMBIENT",
                            reading_timestamp=timestamp,
                            reading_value=round(temperature, 1),
                            unit="C",
                            reading_quality="Good",
                            alarm_status=temp_alarm,
                            alarm_threshold=35.0,
                        )
                    )
                    telemetry_id += 1

            current_date += timedelta(days=1)

    return readings


def generate_work_orders(failure_events: list[FailureEvent]) -> list[WorkOrder]:
    work_orders = []
    wo_id = 3000

    technicians = [
        "John Martinez",
        "Sarah Chen",
        "Mike Thompson",
        "Robert Wilson",
        "Luis Garcia",
    ]

    failure_code_map = {
        "BEARING_WEAR": "MECH-BEAR",
        "BRACKET_LOOSE": "VIB-09",
        "MOTOR_OVERLOAD": "ELEC-MOTOR",
        "ELECTRICAL_FAULT": "ELEC-CTRL",
    }

    root_cause_map = {
        "BEARING_WEAR": "Normal wear on main drive bearings",
        "BRACKET_LOOSE": "Pneumatic actuator bracket mounting bolts loosened",
        "MOTOR_OVERLOAD": "Motor operating above rated load capacity",
        "ELECTRICAL_FAULT": "Control board component degradation",
    }

    for event in failure_events:
        labor_hours = random.uniform(2.0, 8.0)
        parts_cost = random.uniform(150.0, 2500.0)
        labor_cost = labor_hours * 75.0
        total_cost = parts_cost + labor_cost

        work_orders.append(
            WorkOrder(
                wo_id=f"WO-ML-{wo_id:04d}",
                asset_id=event.asset_id,
                wo_type="Corrective",
                work_description=f"Corrective maintenance - {event.failure_mode.replace('_', ' ').lower()}",
                failure_code=failure_code_map.get(event.failure_mode, "UNKNOWN"),
                root_cause=root_cause_map.get(event.failure_mode, "Under investigation"),
                priority="Critical" if event.failure_mode in ["MOTOR_OVERLOAD", "ELECTRICAL_FAULT"] else "High",
                status="Completed",
                created_date=event.failure_date,
                scheduled_date=event.failure_date,
                completed_date=event.failure_date + timedelta(days=1),
                technician=random.choice(technicians),
                labor_hours=round(labor_hours, 1),
                parts_cost=round(parts_cost, 2),
                labor_cost=round(labor_cost, 2),
                total_repair_cost=round(total_cost, 2),
                mttr_hours=round(labor_hours, 1),
                downtime_hours=round(labor_hours * 1.3, 1),
            )
        )
        wo_id += 1

    for asset_id in ASSETS:
        pm_date = START_DATE + timedelta(days=random.randint(30, 60))
        pm_count = 0
        while pm_date < END_DATE and pm_count < 5:
            labor_hours = random.uniform(1.5, 4.0)
            parts_cost = random.uniform(50.0, 300.0)
            labor_cost = labor_hours * 75.0

            work_orders.append(
                WorkOrder(
                    wo_id=f"WO-ML-{wo_id:04d}",
                    asset_id=asset_id,
                    wo_type="Preventive",
                    work_description="Scheduled preventive maintenance",
                    failure_code="PM-QTRLY",
                    root_cause="Scheduled",
                    priority="Medium",
                    status="Completed",
                    created_date=pm_date - timedelta(days=7),
                    scheduled_date=pm_date,
                    completed_date=pm_date,
                    technician=random.choice(technicians),
                    labor_hours=round(labor_hours, 1),
                    parts_cost=round(parts_cost, 2),
                    labor_cost=round(labor_cost, 2),
                    total_repair_cost=round(parts_cost + labor_cost, 2),
                    mttr_hours=round(labor_hours, 1),
                    downtime_hours=round(labor_hours * 1.2, 1),
                )
            )
            wo_id += 1
            pm_count += 1
            pm_date += timedelta(days=random.randint(75, 95))

    return work_orders


def generate_failure_labels(failure_events: list[FailureEvent]) -> list[FailureLabel]:
    labels = []
    label_id = 1

    observation_horizons = [30, 14, 7, 3, 1]

    for event in failure_events:
        for days_before in observation_horizons:
            observation_date = event.failure_date - timedelta(days=days_before)

            if observation_date >= event.cycle_start_date and observation_date >= START_DATE:
                labels.append(
                    FailureLabel(
                        label_id=f"LBL-{label_id:05d}",
                        asset_id=event.asset_id,
                        observation_date=observation_date,
                        actual_failure_date=event.failure_date,
                        days_to_failure=days_before,
                        failure_mode=event.failure_mode,
                        is_failure_imminent=days_before <= 7,
                    )
                )
                label_id += 1

    for asset_id in ASSETS:
        for _ in range(8):
            random_date = START_DATE + timedelta(days=random.randint(30, TOTAL_DAYS - 30))

            is_near_failure = False
            for event in failure_events:
                if event.asset_id == asset_id:
                    days_diff = abs((random_date - event.failure_date).days)
                    if days_diff < 45:
                        is_near_failure = True
                        break

            if not is_near_failure:
                labels.append(
                    FailureLabel(
                        label_id=f"LBL-{label_id:05d}",
                        asset_id=asset_id,
                        observation_date=random_date,
                        actual_failure_date=None,
                        days_to_failure=999,
                        failure_mode="HEALTHY",
                        is_failure_imminent=False,
                    )
                )
                label_id += 1

    return labels


def generate_sql_insert_telemetry(readings: list[TelemetryReading]) -> str:
    sql_parts = [
        "-- Generated SCADA Telemetry Data for ML Training",
        f"-- Total readings: {len(readings)}",
        "",
        "CREATE OR REPLACE TABLE RAW_DATA.SCADA_TELEMETRY_ML (",
        "    TELEMETRY_ID VARCHAR(20) PRIMARY KEY,",
        "    ASSET_ID VARCHAR(20) NOT NULL,",
        "    SENSOR_TYPE VARCHAR(50) NOT NULL,",
        "    SENSOR_NAME VARCHAR(50),",
        "    READING_TIMESTAMP TIMESTAMP_NTZ NOT NULL,",
        "    READING_VALUE NUMBER(10,2),",
        "    UNIT VARCHAR(20),",
        "    READING_QUALITY VARCHAR(20),",
        "    ALARM_STATUS VARCHAR(20),",
        "    ALARM_THRESHOLD NUMBER(10,2)",
        ");",
        "",
    ]

    batch_size = 500
    for i in range(0, len(readings), batch_size):
        batch = readings[i : i + batch_size]
        values = []
        for r in batch:
            ts = r.reading_timestamp.strftime("%Y-%m-%d %H:%M:%S")
            values.append(
                f"('{r.telemetry_id}', '{r.asset_id}', '{r.sensor_type}', '{r.sensor_name}', "
                f"'{ts}', {r.reading_value}, '{r.unit}', '{r.reading_quality}', "
                f"'{r.alarm_status}', {r.alarm_threshold})"
            )

        sql_parts.append(f"INSERT INTO RAW_DATA.SCADA_TELEMETRY_ML VALUES")
        sql_parts.append(",\n".join(values) + ";")
        sql_parts.append("")

    return "\n".join(sql_parts)


def generate_sql_insert_work_orders(work_orders: list[WorkOrder]) -> str:
    sql_parts = [
        "-- Generated Work Orders for ML Training",
        f"-- Total work orders: {len(work_orders)}",
        "",
        "CREATE OR REPLACE TABLE RAW_DATA.WORK_ORDERS_ML (",
        "    WO_ID VARCHAR(20) PRIMARY KEY,",
        "    ASSET_ID VARCHAR(20) NOT NULL,",
        "    WO_TYPE VARCHAR(20) NOT NULL,",
        "    WORK_DESCRIPTION VARCHAR(500),",
        "    FAILURE_CODE VARCHAR(20),",
        "    ROOT_CAUSE VARCHAR(200),",
        "    PRIORITY VARCHAR(20),",
        "    STATUS VARCHAR(20) NOT NULL,",
        "    CREATED_DATE DATE NOT NULL,",
        "    SCHEDULED_DATE DATE,",
        "    COMPLETED_DATE DATE,",
        "    TECHNICIAN VARCHAR(100),",
        "    LABOR_HOURS NUMBER(5,1),",
        "    PARTS_COST NUMBER(10,2),",
        "    LABOR_COST NUMBER(10,2),",
        "    TOTAL_REPAIR_COST NUMBER(10,2),",
        "    MTTR_HOURS NUMBER(5,1),",
        "    DOWNTIME_HOURS NUMBER(5,1)",
        ");",
        "",
        "INSERT INTO RAW_DATA.WORK_ORDERS_ML VALUES",
    ]

    values = []
    for wo in work_orders:
        created = wo.created_date.strftime("%Y-%m-%d")
        scheduled = wo.scheduled_date.strftime("%Y-%m-%d")
        completed = wo.completed_date.strftime("%Y-%m-%d") if wo.completed_date else "NULL"
        desc = wo.work_description.replace("'", "''")
        root_cause = wo.root_cause.replace("'", "''")

        if completed == "NULL":
            completed_str = "NULL"
        else:
            completed_str = f"'{completed}'"

        values.append(
            f"('{wo.wo_id}', '{wo.asset_id}', '{wo.wo_type}', '{desc}', "
            f"'{wo.failure_code}', '{root_cause}', '{wo.priority}', '{wo.status}', "
            f"'{created}', '{scheduled}', {completed_str}, '{wo.technician}', "
            f"{wo.labor_hours}, {wo.parts_cost}, {wo.labor_cost}, {wo.total_repair_cost}, "
            f"{wo.mttr_hours}, {wo.downtime_hours})"
        )

    sql_parts.append(",\n".join(values) + ";")
    return "\n".join(sql_parts)


def generate_sql_insert_labels(labels: list[FailureLabel]) -> str:
    sql_parts = [
        "-- Generated Failure Labels for ML Training",
        f"-- Total labels: {len(labels)}",
        "",
        "CREATE OR REPLACE TABLE RAW_DATA.FAILURE_LABELS_ML (",
        "    LABEL_ID VARCHAR(20) PRIMARY KEY,",
        "    ASSET_ID VARCHAR(20) NOT NULL,",
        "    OBSERVATION_DATE DATE NOT NULL,",
        "    ACTUAL_FAILURE_DATE DATE,",
        "    DAYS_TO_FAILURE NUMBER(10,0) NOT NULL,",
        "    FAILURE_MODE VARCHAR(50) NOT NULL,",
        "    IS_FAILURE_IMMINENT BOOLEAN NOT NULL",
        ");",
        "",
        "INSERT INTO RAW_DATA.FAILURE_LABELS_ML VALUES",
    ]

    values = []
    for lbl in labels:
        obs_date = lbl.observation_date.strftime("%Y-%m-%d")
        if lbl.actual_failure_date:
            fail_date = f"'{lbl.actual_failure_date.strftime('%Y-%m-%d')}'"
        else:
            fail_date = "NULL"
        imminent = "TRUE" if lbl.is_failure_imminent else "FALSE"

        values.append(
            f"('{lbl.label_id}', '{lbl.asset_id}', '{obs_date}', {fail_date}, "
            f"{lbl.days_to_failure}, '{lbl.failure_mode}', {imminent})"
        )

    sql_parts.append(",\n".join(values) + ";")
    return "\n".join(sql_parts)


def generate_csv_telemetry(readings: list[TelemetryReading], filepath: str):
    import csv
    with open(filepath, 'w', newline='') as f:
        writer = csv.writer(f)
        for r in readings:
            ts = r.reading_timestamp.strftime("%Y-%m-%d %H:%M:%S")
            writer.writerow([
                r.telemetry_id, r.asset_id, r.sensor_type, r.sensor_name,
                ts, r.reading_value, r.unit, r.reading_quality,
                r.alarm_status, r.alarm_threshold
            ])


def generate_csv_work_orders(work_orders: list[WorkOrder], filepath: str):
    import csv
    with open(filepath, 'w', newline='') as f:
        writer = csv.writer(f)
        for wo in work_orders:
            created = wo.created_date.strftime("%Y-%m-%d")
            scheduled = wo.scheduled_date.strftime("%Y-%m-%d")
            completed = wo.completed_date.strftime("%Y-%m-%d") if wo.completed_date else ""
            writer.writerow([
                wo.wo_id, wo.asset_id, wo.wo_type, wo.work_description,
                wo.failure_code, wo.root_cause, wo.priority, wo.status,
                created, scheduled, completed, wo.technician,
                wo.labor_hours, wo.parts_cost, wo.labor_cost, wo.total_repair_cost,
                wo.mttr_hours, wo.downtime_hours
            ])


def generate_csv_labels(labels: list[FailureLabel], filepath: str):
    import csv
    with open(filepath, 'w', newline='') as f:
        writer = csv.writer(f)
        for lbl in labels:
            obs_date = lbl.observation_date.strftime("%Y-%m-%d")
            fail_date = lbl.actual_failure_date.strftime("%Y-%m-%d") if lbl.actual_failure_date else ""
            imminent = "TRUE" if lbl.is_failure_imminent else "FALSE"
            writer.writerow([
                lbl.label_id, lbl.asset_id, obs_date, fail_date,
                lbl.days_to_failure, lbl.failure_mode, imminent
            ])


def main():
    print("=" * 70)
    print("STERIS Predictive Maintenance ML - Synthetic Data Generator")
    print("=" * 70)

    print("\n[1/4] Generating failure events...")
    failure_events = generate_failure_events()
    print(f"      Generated {len(failure_events)} failure events")

    failure_mode_counts = {}
    for event in failure_events:
        failure_mode_counts[event.failure_mode] = failure_mode_counts.get(event.failure_mode, 0) + 1
    print(f"      Distribution: {failure_mode_counts}")

    print("\n[2/4] Generating SCADA telemetry...")
    telemetry = generate_telemetry(failure_events)
    print(f"      Generated {len(telemetry)} telemetry readings")

    print("\n[3/4] Generating work orders...")
    work_orders = generate_work_orders(failure_events)
    corrective_count = sum(1 for wo in work_orders if wo.wo_type == "Corrective")
    preventive_count = sum(1 for wo in work_orders if wo.wo_type == "Preventive")
    print(f"      Generated {len(work_orders)} work orders ({corrective_count} corrective, {preventive_count} preventive)")

    print("\n[4/4] Generating failure labels...")
    labels = generate_failure_labels(failure_events)
    failure_labels = sum(1 for lbl in labels if lbl.failure_mode != "HEALTHY")
    healthy_labels = sum(1 for lbl in labels if lbl.failure_mode == "HEALTHY")
    print(f"      Generated {len(labels)} labels ({failure_labels} failure, {healthy_labels} healthy)")

    print("\n" + "=" * 70)
    print("Writing SQL files...")
    print("=" * 70)

    telemetry_sql = generate_sql_insert_telemetry(telemetry)
    with open("sql/10_ml_scada_telemetry.sql", "w") as f:
        f.write("USE ROLE SF_INTELLIGENCE_DEMO;\n")
        f.write("USE DATABASE STERIS_RELIABILITY_DB;\n")
        f.write("USE WAREHOUSE STERIS_ANALYTICS_WH;\n\n")
        f.write(telemetry_sql)
    print(f"      Written: sql/10_ml_scada_telemetry.sql")

    work_orders_sql = generate_sql_insert_work_orders(work_orders)
    with open("sql/11_ml_work_orders.sql", "w") as f:
        f.write("USE ROLE SF_INTELLIGENCE_DEMO;\n")
        f.write("USE DATABASE STERIS_RELIABILITY_DB;\n")
        f.write("USE WAREHOUSE STERIS_ANALYTICS_WH;\n\n")
        f.write(work_orders_sql)
    print(f"      Written: sql/11_ml_work_orders.sql")

    labels_sql = generate_sql_insert_labels(labels)
    with open("sql/12_ml_failure_labels.sql", "w") as f:
        f.write("USE ROLE SF_INTELLIGENCE_DEMO;\n")
        f.write("USE DATABASE STERIS_RELIABILITY_DB;\n")
        f.write("USE WAREHOUSE STERIS_ANALYTICS_WH;\n\n")
        f.write(labels_sql)
    print(f"      Written: sql/12_ml_failure_labels.sql")

    print("\n[CSV Export]")
    generate_csv_telemetry(telemetry, "data/scada_telemetry_ml.csv")
    print(f"      Written: data/scada_telemetry_ml.csv")
    generate_csv_work_orders(work_orders, "data/work_orders_ml.csv")
    print(f"      Written: data/work_orders_ml.csv")
    generate_csv_labels(labels, "data/failure_labels_ml.csv")
    print(f"      Written: data/failure_labels_ml.csv")

    print("\n" + "=" * 70)
    print("DATA GENERATION SUMMARY")
    print("=" * 70)
    print(f"  SCADA Telemetry Readings: {len(telemetry):,}")
    print(f"  Work Orders:              {len(work_orders):,}")
    print(f"  Failure Labels:           {len(labels):,}")
    print(f"  Failure Events:           {len(failure_events):,}")
    print("")
    print("  Failure Mode Distribution:")
    for mode, count in sorted(failure_mode_counts.items()):
        pct = count / len(failure_events) * 100
        print(f"    {mode}: {count} ({pct:.1f}%)")
    print("")
    print("Next Steps:")
    print("  1. Run: sql/10_ml_scada_telemetry.sql")
    print("  2. Run: sql/11_ml_work_orders.sql")
    print("  3. Run: sql/12_ml_failure_labels.sql")
    print("  4. Continue with Feature Store setup notebook")
    print("=" * 70)


if __name__ == "__main__":
    main()
