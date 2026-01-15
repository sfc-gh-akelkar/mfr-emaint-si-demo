# STERIS Factory of the Future - Architecture

## Key Pieces of the Puzzle

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                                                                 │
│                          ❄️ Snowflake Intelligence                              │
│                              User Interface                                     │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                  AI & ML                                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │  Cortex Analyst │  │  Cortex Search  │  │  Snowpark ML    │  │   Cortex    │ │
│  │─────────────────│  │─────────────────│  │─────────────────│  │   Agents    │ │
│  │ Natural Language│  │   Technician    │  │    Failure      │  │─────────────│ │
│  │    To SQL       │  │    Knowledge    │  │   Prediction    │  │Orchestration│ │
│  │                 │  │    Retrieval    │  │    Models       │  │  & Tooling  │ │
│  │ ✅ In Demo      │  │ ✅ In Demo      │  │ 🔮 Future       │  │ ✅ In Demo  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   Data                                          │
│  ┌───────────────────────┐  ┌───────────────────────┐  ┌─────────────────────┐  │
│  │    Ignition SCADA     │  │      eMaint CMMS      │  │    Sepasoft MES     │  │
│  │───────────────────────│  │───────────────────────│  │─────────────────────│  │
│  │ • Vibration Sensors   │  │ • Work Orders         │  │ • Production Runs   │  │
│  │ • Temperature         │  │ • Asset Registry      │  │ • OEE Metrics       │  │
│  │ • Pressure            │  │ • Technician Notes    │  │ • Quality Data      │  │
│  │ • Equipment Status    │  │ • Maintenance History │  │ • Availability      │  │
│  └───────────────────────┘  └───────────────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## Component Mapping

| Layer | Component | STERIS Implementation | Status |
|-------|-----------|----------------------|--------|
| **Interface** | Snowflake Intelligence | Conversational AI Chatbot | ✅ Live |
| **AI & ML** | Cortex Analyst | `MAINTENANCE_SEMANTIC_VW` | ✅ In Demo |
| **AI & ML** | Cortex Search | `TECH_NOTES_SEARCH_SERVICE` | ✅ In Demo |
| **AI & ML** | Snowpark ML | Failure Prediction Models | 🔮 Future |
| **AI & ML** | Cortex Agents | `STERIS_RELIABILITY_AGENT` | ✅ In Demo |
| **Data** | IoT/SCADA | `IGNITION_SCADA_TELEMETRY` | ✅ In Demo |
| **Data** | CMMS | `EMAINT_ASSETS`, `EMAINT_WORK_ORDERS`, `TECH_NOTES` | ✅ In Demo |
| **Data** | MES | `SEPASOFT_MES_PRODUCTION` | ✅ In Demo |

---

## Data Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Ignition   │     │    eMaint    │     │   Sepasoft   │
│    SCADA     │     │    CMMS      │     │     MES      │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────┐
│                   Snowflake (Raw Data)                  │
│  IGNITION_SCADA_TELEMETRY │ EMAINT_* │ SEPASOFT_MES_*  │
└─────────────────────────────┬───────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                   Semantic Layer                        │
│          MAINTENANCE_SEMANTIC_VW (Cortex Analyst)       │
│          TECH_NOTES_SEARCH_SERVICE (Cortex Search)      │
└─────────────────────────────┬───────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                   Cortex Agent                          │
│              STERIS_RELIABILITY_AGENT                   │
│     Orchestrates Analyst + Search for unified answers   │
└─────────────────────────────┬───────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                 Snowflake Intelligence                  │
│            Natural Language Q&A Interface               │
└─────────────────────────────────────────────────────────┘
```

---

## Slide-Ready Version (Copy for PowerPoint)

### Title: STERIS Factory of the Future - Architecture

**Top Layer:**
- **Snowflake Intelligence** - User Interface

**Middle Layer (AI & ML):**
| Cortex Analyst | Cortex Search | Snowpark ML | Cortex Agents |
|----------------|---------------|-------------|---------------|
| Natural Language to SQL | Technician Knowledge Retrieval | Failure Prediction Models | Orchestration & Tooling |

**Bottom Layer (Data):**
| Ignition SCADA | eMaint CMMS | Sepasoft MES |
|----------------|-------------|--------------|
| Vibration Sensors | Work Orders | Production Runs |
| Temperature | Asset Registry | OEE Metrics |
| Pressure | Technician Notes | Quality Data |
| Equipment Status | Maintenance History | Availability |

---

## What Each Component Does

### Cortex Analyst (Semantic View)
- Translates natural language to SQL
- Understands "maintenance cost", "MTTR", "OEE"
- Powers structured data queries

### Cortex Search (Tech Notes Service)
- Searches unstructured technician notes
- Finds tribal knowledge and past fixes
- Semantic search - understands meaning, not just keywords

### Cortex Agent (Reliability Agent)
- Orchestrates Analyst + Search together
- Decides which tool to use for each question
- Provides unified, coherent answers

### Snowpark ML (Future)
- Predictive failure models
- Anomaly detection
- Remaining useful life estimation
