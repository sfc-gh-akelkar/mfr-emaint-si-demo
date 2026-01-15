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

## 🎭 Demo Script (Exact Phrases to Say)

---

### **Q1. Cost Analysis** (Warm-up)

**🗣️ SAY**: "Let's start simple. I want to see maintenance costs across all our plants."

**💬 TYPE**: "What's the total maintenance cost by plant?"

**⏳ WAIT FOR RESPONSE**

**🗣️ SAY AFTER**: "Instant cost visibility - Plant A, Plant B, Hendrix - all in seconds. No waiting for month-end reports. Notice how Hendrix has the most work orders but the lowest total cost? That efficiency story is already emerging."

**➡️ TRANSITION**: "Let's dig deeper into that Hendrix advantage..."

---

### **Q2. Benchmarking** (The Hendrix Story)

**🗣️ SAY**: "Hendrix is our Lighthouse facility - the new best-practice plant. Let's see how it compares."

**💬 TYPE**: "How is Hendrix performing compared to our other plants?"

**⏳ WAIT FOR RESPONSE**

**🗣️ SAY AFTER**: "This is the money slide. Hendrix repairs are 56% faster. OEE is 28% higher. Costs are 55% lower. Your Lighthouse facility is proving the model works - and now you can quantify exactly how much better with hard numbers."

**➡️ TRANSITION**: "Let's look at production performance. OEE tells us how efficiently our packaging lines are running..."

---

### **Q3. OEE Performance** (Surface the Problem)

**🗣️ SAY**: "OEE - Overall Equipment Effectiveness - combines availability, performance, and quality into one metric. Let's see how our packaging machines are doing."

**💬 TYPE**: "Show me OEE for each packaging machine - which ones are underperforming?"

**⏳ WAIT FOR RESPONSE**

**🗣️ SAY AFTER**: "Look at this spread - Unit #03 is at 100%, but Unit #02 is dragging at 70%. That's a 30-point gap. And notice - the AI didn't just show numbers. It already connected this to a known wobbling issue and told us it's the pneumatic actuator bracket. It's proactively diagnosing the problem."

**➡️ TRANSITION**: "The AI mentioned a bracket issue. Let's ask - has this happened before?"

---

### **Q4. ⭐ History & Permanent Fix** (HERO MOMENT - Tribal Knowledge)

**🗣️ SAY**: "This is where it gets interesting. We're going to ask the AI to search technician notes - the tribal knowledge that usually lives in someone's head."

**💬 TYPE**: "Has this wobbling issue happened before? What's the permanent fix?"

**⏳ WAIT FOR RESPONSE**

**🎯 SAY AFTER (KEY MOMENT)**: "This is the magic. The AI searched your technician notes and found this is a recurring issue - happens every 6-8 weeks. It gave us the exact fix - torque to 45 foot-pounds with thread locker. AND it warned us not to waste time replacing bearings - that's a red herring for this specific machine. A technician could take this answer, grab a torque wrench, and fix it right now. No hunting through manuals, no calling the one guy who knows. That's tribal knowledge made searchable."

**➡️ TRANSITION**: "Let's zoom out and look at failure patterns across all our equipment..."

---

### **Q5. Failure Analysis** (Fleet Patterns)

**🗣️ SAY**: "Beyond this one machine, which assets across our entire fleet are giving us the most trouble?"

**💬 TYPE**: "Which machines fail the most often and why?"

**⏳ WAIT FOR RESPONSE**

**🗣️ SAY AFTER**: "Pattern recognition across all your work orders. The AI ranked our problem assets, showed failure codes, and even distinguished between real bearing failures on one machine versus the misdiagnosed bracket issue on another. That kind of pattern recognition prevents wasted repairs."

**➡️ TRANSITION**: "We're seeing a lot of reactive repairs here. Let me ask a strategic question..."

---

### **Q6. Maintenance Strategy** (The Big Opportunity)

**🗣️ SAY**: "Here's a question for leadership - are we being proactive or reactive with our maintenance?"

**💬 TYPE**: "Are we spending more time fixing broken machines or preventing failures?"

**⏳ WAIT FOR RESPONSE**

**🗣️ SAY AFTER**: "There it is. 81% of our maintenance costs are reactive - fixing things after they break. Only 19% is preventive. Every dollar spent on prevention saves $3.60 in reactive repairs. You're operating at the inverse of industry best practice. The AI just surfaced a 20-30% cost reduction opportunity."

**➡️ TRANSITION**: "One more question about asset economics..."

---

### **Q7. Asset Value Analysis** (Cost Red Flags)

**🗣️ SAY**: "Let's look at which assets are giving us the worst return on maintenance investment."

**💬 TYPE**: "Which assets are costing us the most to maintain relative to their value?"

**⏳ WAIT FOR RESPONSE**

**🗣️ SAY AFTER**: "Look at this - a 1.5-year-old Novus 600 costing $1,200 per year, while a 6-year-old Reliance washer costs just $36 per year. That's a red flag the AI surfaced instantly. New equipment shouldn't cost more to maintain than old equipment. This helps you make data-driven replacement decisions."

**➡️ TRANSITION**: "One final thing I want to show you - how the AI handles questions about data it doesn't have..."

---

### **Q8. 🛡️ Trust Test** (No Hallucinations)

**🗣️ SAY**: "This is important for building trust. Let me ask about something that doesn't exist in our data."

**💬 TYPE**: "How are our CNC machines performing?"

**⏳ WAIT FOR RESPONSE**

**🗣️ SAY AFTER**: "Perfect. The AI didn't make up numbers. It told us the truth - 'We don't have CNC machines in this system' - and listed what we actually do have. This is trustworthy AI that knows its boundaries. When it gives you an answer, you can trust it's grounded in real data."

---

### **Closing** (30 seconds)

**🗣️ SAY**: "In about 15 minutes, we went from 'what are our costs' to 'here's exactly how to fix your worst-performing machine' - including tribal knowledge from technician notes. We identified a 20-30% cost reduction opportunity in your maintenance strategy. And we proved the Hendrix Lighthouse model is working with hard numbers. Questions?"

---

## 🎬 Demo Flow (Recommended Order)

```
1. Cost Analysis (warm-up)
     ↓
2. Benchmarking (Hendrix story - MTTR, OEE, health scores)
     ↓
3. OEE Performance (surface AST-010 problem)
     ↓
4. ⭐ History & Permanent Fix (HERO - Cortex Search tribal knowledge)
     ↓
5. Failure Analysis (fleet-wide patterns)
     ↓
6. Maintenance Strategy (reactive vs preventive - opportunity sizing)
     ↓
7. Asset Value Analysis (cost/age red flags)
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
