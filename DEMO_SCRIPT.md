# STERIS Predictive Maintenance — Demo Script

**Customer:** Perdita Beck, Product Owner — Prognostics & RUL
**Format:** Open this doc side-by-side with the notebook in Snowsight

---

## "Intro"

**SAY:** "Perdita, today I'm going to show you a complete predictive maintenance pipeline — from your raw Ignition SCADA telemetry and eMaint work orders all the way to a prioritized maintenance work queue with RUL predictions, failure mode identification, and component-level diagnostics. The entire thing runs inside Snowflake — no external ML platform, no data movement."

**HIGHLIGHT:** Point to the section table — each row maps to a notebook section.

**PERDITA — Set the hook:** "Everything you asked about — prognostics with specific timeframes, failure identification down to the component, SCADA integration, CMMS history — we'll address each one. And the key differentiator: the data never leaves the platform."

---

## "Session Setup"

Just run it. No commentary needed — sets the role, database, schema, and warehouse.

---

## "Source Data Overview" → "Asset Fleet"

**SAY:** "Let's start with the data. In most organizations, SCADA telemetry lives in one system and CMMS work orders live in another. Engineers export CSVs, email spreadsheets, manually reconcile. Here, both streams land in one governed platform."

**HIGHLIGHT:** 20 assets, each with install date, criticality score, and hourly production impact in dollars.

**PERDITA — SCADA Integration requirement:** "This is your Ignition SCADA data alongside your eMaint failure records. No ETL pipeline stitching them together. They're just... here."

**IF SHE ASKS** "Why only 20 assets?": "This is a demo dataset. The architecture scales — Snowflake handles billions of rows with the same SQL. Adding 2,000 assets changes the warehouse size, not the code."

---

## "SCADA Telemetry Intro" → "SCADA Sample" → "SCADA Readings Per Asset"

**SAY:** "Here's the raw SCADA feed — hourly vibration, temperature, and motor current from every asset. 175,000 readings, sitting in Snowflake, ready to query."

**HIGHLIGHT:** Row count (175K) and the three sensor types. "SCADA Readings Per Asset" shows readings per asset — proves data completeness.

**AHA MOMENT:** "Notice we're querying this with plain SQL. No special connector, no API call to Ignition. The data landed here via standard ingestion and now it's just a table."

---

## "CMMS Failure History Intro" → "Failure Events" → "Downtime Cost"

**SAY:** "And here's the other half — your eMaint failure records. 19 documented failures across 5 assets with root cause, downtime hours, and repair details."

**HIGHLIGHT:** Run "Failure Events" — point to FAILURE_TYPE and COMPONENT_FAILED columns. These become the supervised learning labels.

**PERDITA — CMMS Historical Records requirement:** "This is exactly what you described — using historical maintenance records to train the models. The failure type tells the model WHAT failed, the timestamp tells it WHEN, and the repair hours tell it HOW LONG it took. That's your ground truth."

**WOW MOMENT ("Downtime Cost"):** "And here's the business case — we calculate the actual cost of unplanned downtime per asset using the hourly production impact. This is what we'll use later to prioritize the work queue."

---

## "Data Cleansing Intro" → "Null Check" → "Outlier Detection" → "Reading Frequency"

**SAY:** "Before we build features, we need to validate the data. Are there missing readings? Outliers? Gaps in coverage? With Snowflake, this is pure SQL against the live data — no exporting to pandas for profiling."

**HIGHLIGHT:** Run "Null Check" — zero nulls across all three sensor channels (vibration, temperature, current). "Clean ingestion pipeline — no gaps to impute."

Run "Outlier Detection" — point to the MEAN_VIB, STD_VIB, MEAN_TEMP, STD_TEMP columns: "For each asset, we compute the mean and standard deviation. Then we flag any reading more than 3 standard deviations from that asset's mean — a z-score above 3, which is the extreme 0.3% tail."

Point to the zero outlier counts: "Zero outliers here means the ingestion pipeline is clean — no sensor glitches or transmission errors. In production with real sensor drift, this same query catches anomalies automatically. And notice the per-asset stats vary — AST-004 might run hotter than AST-012. That's why we compute z-scores per asset, not fleet-wide."

**CRITICAL FOR PERDITA:** "This is important — in most setups, data scientists would export this to a Jupyter notebook on their laptop to profile it. Here, the profiling runs where the data lives. No copy, no export, no version mismatch."

---

## "Feature Engineering Intro" → "Create Feature View" → "Feature Sample AST-002" → "Feature Row Count"

**SAY:** "This is where raw readings become learnable patterns. We take 175,000 hourly sensor readings and compute 24 engineered features using SQL window functions — rolling averages, trend percentages, z-scores, and CMMS cumulative metrics."

**HIGHLIGHT:** Point to the 4 feature categories in the markdown. When you run "Create Feature View", say: "Watch this — 24 features computed over 175K rows, and it runs in seconds on elastic compute. No Spark cluster to provision."

**AHA MOMENT ("Feature Sample AST-002"):** "Let me show you a specific asset. AST-002 on October 14th: vibration is 0.78 mm/s daily but the 7-day average is 0.75 — and the trend is UP 5.4%. The z-score is 2.39, meaning it's approaching statistical anomaly. It's had 3 corrective work orders, and it's been 14 days since the last one. THESE are the patterns the model learns from."

**PERDITA — This is your 'aha' moment:** "This is exactly what your team described — taking SCADA telemetry and CMMS history and turning them into prognostic features. The vibration trend tells you it's getting worse. The z-score tells you how abnormal it is. The CMMS features tell you it has a history. Together, they predict WHEN and WHAT will fail."

---

## "Feature Row Count"

Quick validation. "7,300 asset-days of features across the fleet."

---

## "Labeled Dataset Intro" → "Create Labeled View" → "Labeled Dataset Sample"

**SAY:** "Each row is now one asset-day with 24 features. And because these are Snowflake views, they auto-refresh as new sensor data arrives. There's no batch ETL to re-run."

**IF SHE ASKS** "Why not use Snowflake's native Feature Store?": "Great question. The Feature Store is ideal for production deployments with versioned feature sets and point-in-time lookups. For this demo, SQL views give us the same auto-refresh behavior with simpler setup. In production, we'd likely migrate these views into the Feature Store for version control and time-travel capabilities."

**SAY ("Create Labeled View" → "Labeled Dataset Sample"):** "Now we create our training labels. For every feature-day within 90 days of a known failure, we know exactly what failed and how many days until it happened."

**HIGHLIGHT ("Labeled Dataset Sample"):** Point to the DAYS_TO_FAILURE column — "This is the RUL target. The model learns: 'when features look like THIS, failure is X days away.'"

**CRITICAL FOR PERDITA:** "Notice the gap assignment logic — when an asset has multiple failures, we assign each feature-day to the NEXT upcoming failure only. This prevents mislabeling between failure events."

---

## "Model Training Intro" → "Python Imports" → "Load Training Data"

**SAY:** "Now for the ML. Two models, both trained right here in this notebook using Snowpark Python. The data never leaves Snowflake."

**PERDITA — Prognostics & RUL requirement:** "The regressor answers 'WHEN will it fail?' — that's your RUL with specific timeframes. The classifier answers 'WHAT will fail and WHY?' — that's your failure identification down to the component."

**WOW MOMENT ("Python Imports"):** "Notice — I'm importing XGBoost, scikit-learn, and pandas right here in the same notebook where we just wrote SQL. SQL for feature engineering, Python for model training, same session, same governance. That's the Snowflake advantage."

**"Load Training Data" output:** "Training dataset: 2,522 samples — 1,261 failure plus 1,261 healthy, balanced equally."

**IF SHE ASKS** about balanced training: "We balance healthy and failure samples equally so the model doesn't just learn to predict 'healthy' for everything — which is what 95% of the data actually is."

---

## "RUL Regression Intro" → "Train RUL Model"

**SAY:** "First model: RUL regression. We're training XGBoost on 2,500 samples to predict days until failure."

**HIGHLIGHT THE RESULTS:** "MAE of 1.83 days means on average, the prediction is off by less than 2 days. R-squared of 0.98 means the model explains 98% of the variance in time-to-failure. For maintenance planning, that's extremely actionable."

**PERDITA — This is her #1 requirement:** "This is exactly what you asked for — prognostics with specific timeframes. Not a risk score, not a traffic light. An actual number of days until failure, accurate to within 2 days."

---

## "Classifier Intro" → "Train Classifier"

**SAY:** "Second model: failure mode classification. Same 24 features, but now predicting WHICH type of failure is approaching — bearing wear, bracket loose, motor overload, or electrical fault. Each maps to a specific component."

**HIGHLIGHT THE RESULTS:** "80% accuracy with a time-based train/test split — we train on January through August failures and test on September through December. This is honest ML: the model has never seen the test data's time period, just like production."

**PERDITA — Failure Identification requirement:** "This answers your second big question: not just WHEN but WHAT. Instead of 'check AST-010,' it's 'the motor bearing on AST-010 is degrading.' That's the difference between a site visit and a targeted repair."

**IF SHE ASKS** about 80% vs higher accuracy: "We deliberately use a time-based split to prevent data leakage. A random split gave 100% — too perfect, because the model was memorizing time windows instead of learning sensor patterns. 80% on truly unseen future data is a strong result, and it improves as you collect more failure events."

**KEY INSIGHT:** "BEARING_WEAR has perfect recall because we have 681 training samples. ELECTRICAL_FAULT has lower representation — 87 samples from one asset. More failure data equals better classification — which is another reason to consolidate everything in Snowflake."

---

## "Predictions Intro" → "Score Fleet"

**SAY:** "Now we score the entire fleet. Both models run against every asset's latest sensor features — one Python call, results in seconds."

**WOW MOMENT — Pause on the output table:** "Look at this. Every asset in your fleet, ranked by urgency. AST-004 — motor bearing, 7 days. AST-015 — control board, 7 days but 78% confidence — lower confidence because we had fewer electrical fault training examples. AST-001 — motor overload, 73 days out, plenty of time to plan."

**PERDITA — All four requirements in one table:**
| Column | Her Requirement |
|---|---|
| RUL_DAYS | Prognostics with specific timeframes |
| FAILURE_MODE | Failure identification |
| COMPONENT | Component-level diagnostics |
| CONFIDENCE | Trust calibration |
| FAIL DATE | Maintenance scheduling |

**SAY:** "This is the shift from reactive to predictive. Instead of waiting for AST-004 to fail and scrambling, you schedule the bearing replacement next week."

---

## "Write Predictions Intro" → "Write to Snowflake"

**SAY:** "Now the predictions land as governed Snowflake tables. Two tables: the predictions themselves, and an evidence table documenting WHY each prediction was made — the SCADA readings and CMMS records behind it."

**HIGHLIGHT:** Two table names — ML.COMPONENT_RUL_PREDICTIONS (20 rows) and ML.PREDICTION_EVIDENCE (80 rows, 4 per asset).

**PERDITA — Operational readiness:** "These are immediately queryable. Your Tableau dashboard, your Power BI report, your eMaint integration — they can all read from this table right now. No file export, no API. Same RBAC that governs the source data governs the predictions."

---

## "High-Risk Drill Down Intro" → "High-Risk Assets"

**SAY:** "Now watch this — a maintenance supervisor who knows zero Python can write this SQL query: 'Show me every asset failing within 30 days, sorted by urgency.' That's it. ML outputs are just tables."

**AHA MOMENT:** "The person who built the model and the person who acts on the predictions don't need to use the same tools. Data scientist works in Python, maintenance planner works in SQL or Tableau. Same data, same governance."

---

## "Prediction Evidence Intro" → "Evidence Detail"

**SAY:** "Here's what sets this apart from a black-box ML tool. Every prediction has evidence: the specific vibration reading, the temperature, the CMMS work order history that drove it."

**HIGHLIGHT:** Point to the 4 evidence rows for AST-010 — SCADA_VIBRATION, SCADA_TEMPERATURE, CMMS_HISTORY, FAILURE_PATTERN_MATCH.

**PERDITA — Trust and adoption:** "Your maintenance team won't act on a number they can't explain. This evidence table means any technician can ask 'why does the model think this bearing is failing?' and get a concrete answer: 'because vibration is trending up 5%, it's had 3 corrective WOs, and the pattern matches bearing wear with 94% confidence.' That's how you get adoption."

---

## "Work Queue Intro" → "Maintenance Work Queue" (GRAND FINALE)

**SAY:** "And here's the deliverable. A prioritized maintenance work queue — sorted by urgency, with the predicted failure mode, component at risk, confidence level, and the dollar cost of downtime per hour."

**WOW MOMENT — Linger on this output:** "AST-004: motor bearing, 7 days, URGENT, $4,500/hour production impact. AST-001: motor overload, 73 days, LOW priority. Your team now knows exactly what to schedule, when, and what it costs if they don't."

**PERDITA — The close:** "This is the bridge from data science to operations. This query can feed your eMaint system directly. It can be a Tableau dashboard. It can be a daily email. And it updates every time the models re-score — because the features auto-refresh from live SCADA data."

**KEY POINT:** "Everything you just saw — from raw sensor data to this work queue — runs inside Snowflake. One platform, one governance model, no data movement. That's the value proposition."

---

## "Summary"

**SAY:** "Let me tie this back to what you asked for."

Walk through the requirements table:
| Perdita's Requirement | What We Just Showed |
|---|---|
| Prognostics & RUL | XGBoost regression — MAE 1.83 days, R-squared 0.98 |
| Failure Identification | XGBoost classifier — failure mode to component, 80% accuracy |
| SCADA Integration | 175K Ignition readings to 24 features to predictions |
| CMMS Historical Records | eMaint failure events + cumulative WOs as model inputs |

**SAY — The five Snowflake differentiators:**
1. "Zero data movement — SCADA, CMMS, features, models, and predictions all in one platform"
2. "SQL plus Python in one notebook — feature engineering in SQL, model training in Python, same governance"
3. "Elastic compute — warehouse scales up for training, scales down after. Pay only for what you use"
4. "Operational readiness — predictions are tables. Any BI tool, dashboard, or CMMS can query them today"
5. "Full traceability — every prediction traces back to the SCADA reading and CMMS record that drove it"

**CLOSING STATEMENT:**

"The shift is this:

BEFORE: 'AST-010 has high risk' — opaque score, external tool, data exported somewhere.

AFTER: 'AST-010 motor bearing will fail in 11 days because vibration is trending up and the asset has 5 corrective WOs on record' — explainable, traceable, governed, actionable, all in Snowflake.

That's what we can build together. Questions?"
