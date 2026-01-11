# STERIS "Factory of the Future" AI Reliability Platform

## Overview

This demo showcases how **Snowflake Intelligence** can transform STERIS's maintenance operations from manual, Excel-based workflows to an AI-powered Asset Reliability Platform. The demo is designed for the **Hendrix Lighthouse** facility and includes data from legacy plants for benchmarking.

## Business Context

STERIS is a leader in infection prevention and sterilization. Their current maintenance strategy has a significant gap:
- The **eMaint CMMS** is poorly deployed and underutilized
- Data flows manually via Excel and email
- Critical tribal knowledge is trapped in technician notebooks

This demo shows how Snowflake Intelligence solves these challenges.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     SNOWFLAKE INTELLIGENCE                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    CORTEX AGENT                                   │   │
│  │            "STERIS Asset Reliability Assistant"                   │   │
│  │                                                                   │   │
│  │   ┌─────────────────────┐     ┌─────────────────────────────┐   │   │
│  │   │   CORTEX ANALYST    │     │     CORTEX SEARCH           │   │   │
│  │   │                     │     │                             │   │   │
│  │   │  • Maintenance      │     │  • Technician Notes        │   │   │
│  │   │    Costs & MTTR     │     │  • Troubleshooting Tips    │   │   │
│  │   │  • Asset Health     │     │  • Repair Procedures       │   │   │
│  │   │  • OEE Metrics      │     │  • Tribal Knowledge        │   │   │
│  │   │  • Plant Benchmarks │     │                             │   │   │
│  │   │                     │     │                             │   │   │
│  │   └─────────┬───────────┘     └──────────────┬──────────────┘   │   │
│  │             │                                │                    │   │
│  └─────────────┼────────────────────────────────┼────────────────────┘   │
│                │                                │                        │
│  ┌─────────────▼───────────┐     ┌──────────────▼──────────────┐        │
│  │    SEMANTIC VIEW        │     │   CORTEX SEARCH SERVICE     │        │
│  │  MAINTENANCE_SEMANTIC_VW│     │  TECH_NOTES_SEARCH_SERVICE  │        │
│  └─────────────┬───────────┘     └──────────────┬──────────────┘        │
│                │                                │                        │
└────────────────┼────────────────────────────────┼────────────────────────┘
                 │                                │
      ┌──────────▼────────────────────────────────▼──────────┐
      │                    RAW DATA LAYER                     │
      ├───────────────┬──────────────┬───────────────────────┤
      │  eMaint CMMS  │ Ignition     │  Sepasoft MES         │
      │  • Assets     │ SCADA        │  • Production         │
      │  • Work Orders│ • Telemetry  │  • OEE                │
      │  • Tech Notes │ • Alarms     │  • Quality            │
      └───────────────┴──────────────┴───────────────────────┘
```

## Key Demo Features

### 1. The Novus 600 Wobbling Issue (Star of the Demo!)

The demo includes a carefully crafted scenario around a recurring maintenance issue:

- **Asset**: Novus 600 Packaging Machine #02 (AST-010) at Hendrix
- **Symptom**: Wobbling during operation, vibration spike to 4.5mm/s
- **Red Herring**: Standard troubleshooting suggests bearing replacement
- **Actual Fix**: Realign the pneumatic actuator bracket (45 ft-lbs torque)

This demonstrates how the AI can surface tribal knowledge that would otherwise require finding the right technician to ask.

### 2. Plant Benchmarking

Compare the new Hendrix Lighthouse facility against legacy Plant A and Plant B:
- Asset health scores
- MTTR (Mean Time to Repair)
- Maintenance costs
- Preventive vs Corrective ratio
- OEE (Overall Equipment Effectiveness)

### 3. Data Integration

The demo combines data from multiple systems:
- **eMaint CMMS**: Assets, work orders, technician notes
- **Ignition SCADA**: Real-time telemetry (vibration, temperature, pressure)
- **Sepasoft MES**: Production data and OEE metrics

## Quick Start - Setup Instructions

### Prerequisites

1. Snowflake account with Intelligence features enabled
2. Role `SF_INTELLIGENCE_DEMO` with appropriate privileges
3. Snowsight or SnowSQL access

### Simple Setup (Just Run SQL!)

All demo data is embedded directly in the SQL scripts - no CSV uploads or staging required!

**Run these scripts in order in Snowsight:**

| Step | Script | Description |
|------|--------|-------------|
| 1 | `sql/01_setup_database.sql` | Create database, schemas, and warehouse |
| 2 | `sql/02_create_raw_tables.sql` | Create tables and insert all demo data |
| 3 | `sql/03_create_curated_views.sql` | Create joined analytical views |
| 4 | `sql/04_create_semantic_view.sql` | Create Semantic View for Cortex Analyst |
| 5 | `sql/05_create_cortex_search.sql` | Create Cortex Search Service for tech notes |
| 6 | `sql/06_create_cortex_agent.sql` | Create the Cortex Agent |

**Using SnowSQL:**
```bash
cd sql
snowsql -f 01_setup_database.sql
snowsql -f 02_create_raw_tables.sql
snowsql -f 03_create_curated_views.sql
snowsql -f 04_create_semantic_view.sql
snowsql -f 05_create_cortex_search.sql
snowsql -f 06_create_cortex_agent.sql
```

### Verify Setup

After running all scripts, use `sql/07_demo_queries.sql` to verify the setup and explore the data.

## Demo Data Summary

| Table | Records | Description |
|-------|---------|-------------|
| EMAINT_ASSETS | 20 | Equipment master data (sterilizers, washers, packaging) |
| EMAINT_WORK_ORDERS | 28 | Maintenance history with costs and MTTR |
| TECH_NOTES_UNSTRUCTURED | 50 | Technician logbook entries with tribal knowledge |
| IGNITION_SCADA_TELEMETRY | 62 | Sensor readings including vibration spike on AST-010 |
| SEPASOFT_MES_PRODUCTION | 40 | Production data with OEE metrics |

## Demo Script

### Opening: Set the Stage

> "STERIS's maintenance operations at Hendrix were struggling with manual data flows and underutilized CMMS. Let me show you how Snowflake Intelligence transforms this."

### Demo 1: The Urgent Vibration Alert

**Scenario**: Production calls - the Novus 600 packaging machine is wobbling again!

```
User: "The Novus 600 at Hendrix is showing a vibration spike of 4.5mm/s. 
       What's wrong and how do I fix it?"
```

**What happens**:
1. Agent queries Cortex Analyst for current telemetry and work order history
2. Agent searches Cortex Search for technician notes
3. Agent synthesizes: "This is a known issue. Do NOT replace the bearings - check the pneumatic actuator bracket and torque to 45 ft-lbs."

### Demo 2: Plant Benchmarking

**Scenario**: Leadership wants to see Hendrix performance vs legacy plants

```
User: "Compare maintenance costs and MTTR between Hendrix and our legacy plants"
```

**What happens**:
- Shows Hendrix has lower costs and better MTTR due to newer equipment
- Highlights areas where legacy plants need investment

### Demo 3: Proactive Maintenance

**Scenario**: Identify assets at risk

```
User: "Which assets have health scores below 75 and what should we do about them?"
```

**What happens**:
- Lists at-risk assets
- Provides maintenance recommendations
- Links to relevant work order history

## Key Stakeholder Talking Points

| Challenge | Demo Solution |
|-----------|---------------|
| **Manual Data Flows** | Automated ingestion from eMaint, Ignition, and Sepasoft into Snowflake |
| **CMMS Misunderstanding** | Shows eMaint as an "Intelligence" layer that reduces MTTR, not just task tracking |
| **Fragmented Insights** | Combines SCADA telemetry with technician notes for predictive maintenance |
| **Enterprise Benchmarking** | Cortex Analyst compares Hendrix Lighthouse against legacy plants |
| **Tribal Knowledge Loss** | Cortex Search captures and surfaces technician expertise |

## File Structure

```
steris-emaint-demo/
├── README.md                              # This file
└── sql/                                   # All SQL scripts (just run these!)
    ├── 00_run_all.sql                    # Setup overview and verification
    ├── 01_setup_database.sql             # Database & schema creation
    ├── 02_create_raw_tables.sql          # Tables + INSERT statements (all data)
    ├── 03_create_curated_views.sql       # Analytical views
    ├── 04_create_semantic_view.sql       # Semantic View for Cortex Analyst
    ├── 05_create_cortex_search.sql       # Cortex Search Service
    ├── 06_create_cortex_agent.sql        # Cortex Agent configuration
    └── 07_demo_queries.sql               # Demo & verification queries
```

## Technical References

### Required Documentation (Used to Build This Demo)

| Resource | URL | Used For |
|----------|-----|----------|
| **Semantic View Example** | https://docs.snowflake.com/en/user-guide/views-semantic/example | Creating `MAINTENANCE_SEMANTIC_VW` |
| **Cortex Agents Management** | https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-manage | CREATE AGENT SQL syntax |
| **Agent Best Practices** | https://github.com/Snowflake-Labs/sfquickstarts/blob/master/site/sfguides/src/best-practices-to-building-cortex-agents/best-practices-to-building-cortex-agents.md | Tool orchestration and instructions |

### Additional Documentation

- [Snowflake Semantic Views Overview](https://docs.snowflake.com/en/user-guide/views-semantic/overview)
- [Cortex Search Service Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search)
- [CREATE CORTEX SEARCH SERVICE](https://docs.snowflake.com/en/sql-reference/sql/create-cortex-search)
- [CREATE SEMANTIC VIEW](https://docs.snowflake.com/en/sql-reference/sql/create-semantic-view)

### Role Requirements

All demo assets are created using the **`SF_INTELLIGENCE_DEMO`** role. Ensure this role has:
- `CREATE DATABASE` privilege (or use an existing database)
- `CREATE WAREHOUSE` privilege
- `CREATE AGENT` privilege on the schema
- `CREATE CORTEX SEARCH SERVICE` privilege

## Support

For questions about this demo, contact the Snowflake Solutions Engineering team.

---

**Built with Snowflake Intelligence** 🏔️
