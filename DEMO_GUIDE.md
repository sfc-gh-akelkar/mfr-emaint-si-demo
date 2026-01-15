# STERIS Factory of the Future - Demo Guide

## Snowflake Intelligence Asset Reliability Platform

**Duration**: 15-20 minutes  
**Audience**: STERIS IT, Operations, Maintenance Leadership  
**Demo Environment**: Snowflake Intelligence Chatbot

---

## 🎯 Demo Objectives

1. **Show unified data platform** - eMaint CMMS, Ignition SCADA, Sepasoft MES all queryable together
2. **Demonstrate AI-powered insights** - Natural language questions → actionable answers
3. **Highlight the Hendrix Lighthouse story** - New facility outperforming legacy plants
4. **Surface tribal knowledge** - Cortex Search finds technician notes
5. **Build trust** - AI acknowledges data boundaries, no hallucinations

---

## 🚀 Quick Setup

```sql
-- Run in Snowflake (takes ~2 minutes)
USE ROLE SF_INTELLIGENCE_DEMO;
-- Execute scripts 01-06 from sql/ folder
```

---

## 📋 Demo Script

### **Opening (30 seconds)**
> "Today I'll show you how Snowflake Intelligence can turn your maintenance data into instant, actionable insights. We've integrated your eMaint work orders, SCADA telemetry, and MES production data into a single AI-powered platform."

---

## Demo Questions & Expected Answers

### **1. Cost Analysis**
**Ask**: "What's the total maintenance cost by plant?"

| What to Look For | ✅ Good Answer Includes |
|------------------|------------------------|
| Plant breakdown | Hendrix, Plant A, Plant B with dollar amounts |
| Comparative insight | Hendrix costs higher due to more assets |
| Cost per asset | ~$350-400 range across plants |

**Talking Point**: "Instant cost visibility across all facilities - no more waiting for month-end reports."

---

### **2. Benchmarking (Key Story)**
**Ask**: "How is Hendrix performing compared to our other plants?"

| What to Look For | ✅ Good Answer Includes |
|------------------|------------------------|
| Multi-dimensional comparison | Costs, uptime, health scores, OEE |
| Hendrix advantage | Higher uptime, better health scores |
| Specific metrics | 95%+ uptime at Hendrix vs lower at legacy |

**Talking Point**: "Your Lighthouse facility is proving the model works - now you can quantify exactly how much better."

---

### **3. OEE Performance (Setup for the Problem)**
**Ask**: "Show me OEE for each packaging machine - which ones are underperforming?"

*Alternative phrasing*: "Break down OEE by individual packaging asset"

| What to Look For | ✅ Good Answer Includes |
|------------------|------------------------|
| Per-machine breakdown | Each Novus 600 unit listed separately |
| Clear underperformer | Unit #02 (AST-010) at ~70.6% |
| Top performer | Unit #03 at ~100% for contrast |
| Gap identified | 30 point spread between best/worst |

**Talking Point**: "Instantly see which specific machines are dragging down your line - no digging through reports."

**🎯 Demo Moment**: The agent proactively identified AST-010's issue AND connected it to the root cause. Highlight this:
> "Notice the AI didn't just show numbers - it connected the OEE problem to the known wobbling issue. It's already telling us what's wrong."

**🔗 Transition to Q4**: *Build on what the agent just revealed:*
> "The AI mentioned a 'bracket repair' - let's ask exactly how to fix it..."

---

### **4. History & Permanent Fix (Tribal Knowledge)**
**Ask**: "Has this wobbling issue happened before? What's the permanent fix?"

*Alternative phrasing*: "What's the history of the Novus 600 bracket problem?"

| What to Look For | ✅ Good Answer Includes |
|------------------|------------------------|
| History | Previous occurrences documented |
| Pattern | Recurring issue identified |
| Permanent solution | Replace bracket plate entirely |
| Technician notes | Referenced as source |

**Talking Point**: "The AI just pulled from technician notes to show this is a *recurring* issue - and gave us the permanent fix, not just a band-aid."

**🔗 Why This Works**: Q3 gave the immediate fix. Q4 adds the history and permanent solution - showing tribal knowledge capture.

---

### **5. Failure Analysis**
**Ask**: "Which machines fail the most often and why?"

| What to Look For | ✅ Good Answer Includes |
|------------------|------------------------|
| Ranked list | Novus 600 Packaging highest |
| Failure modes | VIB-09, MECH-ALIGN codes |
| Root causes | Specific technical explanations |
| Recommendations | Actionable next steps |

**Talking Point**: "Pattern recognition across all your work orders - instantly see which assets need attention."

**🔗 Transition to Q6**: *Bridge from failures to maintenance strategy:*
> "We're seeing a lot of reactive repairs. Are we spending more time fixing or preventing failures?"

---

### **6. Maintenance Strategy**
**Ask**: "Are we spending more time fixing broken machines or preventing failures?"

| What to Look For | ✅ Good Answer Includes |
|------------------|------------------------|
| Clear verdict | "More time fixing" |
| Split | 66% corrective / 34% preventive (hours) |
| Cost impact | 78% of costs on reactive maintenance |
| Benchmark | Industry best practice (60/40 preventive) |
| Opportunity | 20-30% cost reduction potential |

**Talking Point**: "You're operating at the inverse of industry best practice. That's a 20-30% cost reduction opportunity the AI just surfaced."

---

### **7. Asset Value Analysis**
**Ask**: "Which assets are costing us the most to maintain relative to their value?"

| What to Look For | ✅ Good Answer Includes |
|------------------|------------------------|
| Cost ranking | Top 3 highest maintenance cost assets |
| Age consideration | Young assets with high costs flagged |
| Health scores | Poor scores for age highlighted |
| Contrast | Best performers (Hendrix $75-113) vs worst ($1,500+) |

**Talking Point**: "A 1.5-year-old Novus 600 costing $1,800 in maintenance is a red flag. Hendrix assets of similar age cost $75-113."

---

### **8. ⭐ HERO QUESTION - Tribal Knowledge**
**Ask**: "The Novus 600 is wobbling, how was this specific problem solved the last time it happened?"

| What to Look For | ✅ Good Answer Includes |
|------------------|------------------------|
| Exact fix | Torque bracket bolts to 45 ft-lbs |
| Thread locker | Mentioned as prevention |
| Warning | "Do NOT replace bearings" |
| Future recommendation | Replace bracket plate at next downtime |
| Source | Technician notes referenced |

**🎯 Key Demo Moment**:
> "This is the magic. A technician could take this answer, grab a torque wrench, and fix the machine right now. No hunting through manuals, no calling the one guy who knows. The AI searched your technician notes and found the exact fix - including the warning that bearings are a red herring."

---

### **9. 🛡️ TRUST TEST - No Hallucinations**

Use these questions to demonstrate the AI doesn't make up data:

#### **Option A: Non-existent Plant**
**Ask**: "What's the maintenance cost for Plant C?"

| What to Look For | ✅ Good Answer Includes |
|------------------|------------------------|
| Acknowledges gap | "Plant C does not exist in our system" |
| Lists valid options | Plant A, Plant B, Hendrix |
| No fake data | Does NOT invent costs for Plant C |
| Helpful redirect | Offers to show real plant data |

#### **Option B: Wrong Equipment Type**
**Ask**: "How are our CNC machines performing?"

| What to Look For | ✅ Good Answer Includes |
|------------------|------------------------|
| Acknowledges gap | "We don't have CNC machines in this system" |
| Explains scope | Lists actual equipment (Sterilizers, Washers, etc.) |
| Domain awareness | "This tracks medical equipment, not manufacturing" |
| No fake data | Does NOT invent CNC performance metrics |

**🎯 Key Demo Moment**:
> "I just asked about something that doesn't exist in our data. The AI didn't make up numbers - it told me the truth and offered to help with what it actually knows. This is trustworthy AI that knows its boundaries."

**Why This Matters**:
- Builds confidence that insights are grounded in real data
- Shows the AI won't lead users astray with fabricated information
- Critical for decision-making trust

---

## 🎬 Demo Flow (Recommended Order)

```
1. Cost Analysis (warm-up)
     ↓
2. Benchmarking (set up Hendrix story - includes MTTR comparison)
     ↓
3. OEE Performance (surface the problem machine)
     ↓
4. History & Permanent Fix (tribal knowledge)
     ↓
5. Failure Analysis (fleet-wide patterns)
     ↓
6. Maintenance Strategy (opportunity sizing)
     ↓
7. ⭐ Hero Question (Cortex Search moment)
     ↓
8. 🛡️ Trust Test (optional - "Plant C" or "CNC machines")
     ↓
9. Wrap-up
```

---

## 💬 Key Talking Points by Stakeholder

### For **IT/Data Teams**:
- "All your data sources unified in one semantic layer"
- "No more report building - users ask questions in plain English"
- "Cortex Search makes unstructured technician notes queryable"

### For **Operations/Plant Managers**:
- "Hendrix repairs 2.5x faster - now you can prove it"
- "Real-time OEE and MTTR visibility across all facilities"
- "Benchmark any metric across plants instantly"

### For **Maintenance Leadership**:
- "66% reactive maintenance means 20-30% cost reduction opportunity"
- "AI finds the fix in technician notes - no more losing tribal knowledge"
- "Young assets with high costs get flagged automatically"

### For **Finance/Executives**:
- "Plant-level cost visibility without month-end reporting"
- "3.5x higher cost for reactive vs preventive maintenance"
- "Quantified ROI of the Lighthouse facility model"

---

## 🔥 If Asked...

**"How hard is this to set up?"**
> "The SQL scripts take about 5 minutes to run. The semantic layer is pure SQL - your team already knows how to maintain it."

**"Can we add more data sources?"**
> "Absolutely. The semantic view can join any data you bring into Snowflake. We've designed it for extensibility."

**"How does it know about the technician fixes?"**
> "Cortex Search indexes your unstructured technician notes. It's semantic search - it understands meaning, not just keywords."

**"Is this real-time?"**
> "As real-time as your data pipelines. SCADA data could stream in, and the AI queries it immediately."

---

## ✅ Demo Checklist

- [ ] SF_INTELLIGENCE_DEMO role has access
- [ ] All 6 SQL scripts executed successfully
- [ ] Snowflake Intelligence chatbot accessible
- [ ] Test 2-3 questions before live demo
- [ ] Have this guide open for reference

---

## 📚 Technical References

| Resource | Link |
|----------|------|
| Semantic Views | https://docs.snowflake.com/en/user-guide/views-semantic/example |
| Cortex Agents | https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-manage |
| Agent Best Practices | https://github.com/Snowflake-Labs/sfquickstarts/blob/master/site/sfguides/src/best-practices-to-building-cortex-agents/best-practices-to-building-cortex-agents.md |

---

*Last validated: January 2026*
