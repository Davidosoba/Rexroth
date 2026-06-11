# Bosch Rexroth AG — Predictive Maintenance Data Analytics

![Project Status](https://img.shields.io/badge/Status-Completed-green)
![Programme](https://img.shields.io/badge/Programme-Amdari%20Work%20Experience-brown)
![Tools](https://img.shields.io/badge/Tools-PostgreSQL%20%7C%20Power%20BI-darkred)

##  Table of Content

-  [Overview](#overview)
-  [Business Context](#Business-Context)
-  [Project Scope](#Project-Scope)
-  [Dataset](#Dataset)
-  [Technology Stack](#Technology-Stack)
-  [Repository Structure](#Repository-Structure)
-  [Database Schema](#Database-Schema)
-  [Key SQL Objects](#Key-SQL-Objects)
-  [Data Cleaning Approach](#Data-Cleaning-Approach)
-  [Dashboard](#Dashboard)
-  [Key Findings](#Key-Findings)
-  [How To Use This Repository](#How-To-Use-This-Repository)
-  [Author](#Author)
-  [Acknowledgements](#Acknowledgements)

## Overview

This repository contains the **data analytics component** of a collaborative predictive maintenance project for **Bosch Rexroth AG**, a globally recognised leader in industrial hydraulics and drive & control technologies.

The project addresses a critical operational challenge — unplanned hydraulic system failures causing significant production downtime and high repair costs. The data analytics scope covers the full pipeline from raw data ingestion through to an interactive Power BI dashboard and stakeholder-ready reporting.

> **Note:** This project was completed as part of the **Amdari Work Experience Programme**. The machine learning component (failure classification and RUL prediction modelling) was handled by a separate team. This repository covers the data analytics lane only.

---

## Business Context

Bosch Rexroth AG operates hydraulic systems critical to continuous production across manufacturing, energy, and heavy machinery sectors. These systems generate vast amounts of time-series sensor data, yet much of this data was underutilised in maintenance decision-making.

**The problem:** Maintenance operations were largely reactive, with failures occurring unexpectedly due to pressure fluctuations, temperature variations, and contamination — resulting in significant downtime, high repair costs, and delayed deliveries.

**The goal:** Build a structured data analytics foundation to identify failure patterns, assess machine health, and provide actionable insights to support the shift from reactive to proactive maintenance.

---

## Project Scope

This repository covers the following stages of the analytics pipeline:

| Stage | Description |
|---|---|
| Data Ingestion | Loading 4 CSV datasets into a PostgreSQL relational database |
| Data Exploration | Validating record counts, checking referential integrity, identifying missing values |
| Data Cleaning | Forward-fill interpolation for sensor dropout events using window functions |
| Data Transformation | Hourly aggregation of minute-level sensor telemetry |
| ERD Design | Entity Relationship Diagram documenting the database schema |
| Power BI Dashboard | 3-page interactive dashboard for maintenance monitoring |
| Insight Report | Structured Word document summarising key findings |
| Presentation | 7-slide executive PowerPoint summarising the analysis |

---

## Dataset

The analysis is based on four structured datasets representing a 10-machine hydraulic fleet monitored over January–February 2024.

| File | Records | Description | Included |
|---|---|---|---|
| `sensor_telemetry.csv` | 864,000 | Minute-level sensor readings per machine | ❎ Excluded - exceeds GitHub 25MB limit |
| `failure_labels.csv` | 9 | Failure events with mode, cost, and downtime | ✅ |
| `maintenance_log.csv` | 51 | Maintenance actions with type, component, and cost | ✅ |
| `equipment_master.csv` | 10 | Machine metadata including fluid type and priority | ✅ |

> **Note:** `sensor_telemetry.csv` is excluded from this repository due to GitHub's 25mb file size limit. The file contains 864,000 rows of minute-level sensor telemetry.

---

**Sensor channels captured:**
- `pressure_bar` — Hydraulic system pressure
- `temp_celsius` — Oil temperature
- `flow_lpm` — Flow rate in litres per minute
- `vibration_x_g` / `vibration_y_g` — Vibration amplitude (X and Y axes)
- `pump_rpm` — Pump rotational speed

---

## Technology Stack

| Layer | Tool |
|---|---|
| Database | PostgreSQL 18 / pgAdmin 4 |
| Connectivity | Devart ODBC Driver for PostgreSQL |
| Visualisation | Power BI Desktop |
| Reporting | Microsoft Word / PowerPoint |
| Version Control | GitHub |

---

## Repository Structure

```
rexroth/
│
├── data/
│   ├── sensor_telemetry.csv
│   ├── failure_labels.csv
│   ├── maintenance_log.csv
│   └── equipment_master.csv
│
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_data_exploration.sql
│   ├── 03_data_cleaning_view.sql
│   └── 04_hourly_aggregation_view.sql
│
├── dashboard/
│   └── Bosch_Rexroth_AG_Dashboard.pbix
│
├── erd/
│   └── bosch_maintenance_erd.png
│
├── reports/
│   ├── Bosch_Rexroth_AG_Data_Analytics_Insight_Report.docx
│   └── Bosch_Rexroth_AG_Data_Analytics_Presentation.pptx
│
└── README.md
```

---

## Database Schema

The database follows a **star schema** with `equipment_master` as the central parent table and three child tables linked via `machine_id`.

```
equipment_master (PK: machine_id)
    │
    ├── sensor_telemetry    (FK: machine_id)
    ├── failure_labels      (FK: machine_id)
    └── maintenance_log     (FK: machine_id)
```

### Key SQL Objects

**Tables:** `equipment_master`, `sensor_telemetry`, `failure_labels`, `maintenance_log`

**Views:**
- `sensor_telemetry_cleaned` — Applies forward-fill interpolation to resolve 2,590 sensor dropout events using `COUNT() OVER` and `MAX() OVER` window functions
- `sensor_telemetry_hourly` — Aggregates 864,000 minute-level records into 14,400 hourly summaries per machine using `DATE_TRUNC`, `AVG`, `MIN`, `MAX`, `SUM`, and `MODE()`

---

## Data Cleaning Approach

**Problem:** 2,590 rows (0.3% of total) had NULL sensor values due to sensor dropout events, flagged in the `is_sensor_dropout` column.

**Approach:** Forward-fill interpolation — carry the last known valid sensor reading forward until the next valid reading appears. This preserves time-series continuity without deleting data or distorting averages.

**Why not delete?** Deleting dropout rows breaks the continuity of the time-series, creating gaps in trend charts in Power BI.

**Why not mean-fill?** Mean-fill ignores the temporal nature of sensor data. A sensor reading is more likely to resemble its immediate neighbours than the overall average.

**Implementation:** PostgreSQL window functions — `COUNT(column) OVER (PARTITION BY machine_id ORDER BY timestamp)` creates a group number that stays constant during NULL sequences, then `MAX(column) OVER (PARTITION BY machine_id, group)` fills each NULL with the last valid value.

---

## Dashboard

The Power BI dashboard is structured across three pages:

### Page 1 — Failure & Maintenance Overview
Answers: *What is failing, how often, and at what cost?*
- KPI cards: Total failure events, total repair cost, total downtime, avg cost per failure
- Most common failure modes (bar chart)
- Downtime hours per machine (bar chart)
- Maintenance count per machine (bar chart)
- Frequency of replaced components (bar chart)
- Average repair cost by failure mode (bar chart)
- Maintenance cost by action type (donut chart)
- Repair cost vs downtime hours (scatter chart)
- Sensor channel deviating earliest before failure (line chart)

### Page 2 — Sensor Health Monitoring
Answers: *How are the sensors and machines behaving over time?*
- KPI cards: Total sensor dropouts, avg anomaly rate, avg RUL hours, highest anomaly machine
- Anomaly rate per machine (bar chart)
- Vibration levels per machine (bar chart)
- Average vibration by failure mode (bar chart)
- Anomaly count by shift (donut chart)
- Avg pressure & temperature over time (dual axis line chart)
- RUL distribution across machines (bar chart)
- Anomaly rate trend over time (line chart)
- Preventive vs reactive impact on downtime (clustered bar chart)

### Page 3 — Financial & Operational Impact
Answers: *What is the business cost and how far are we from target?*
- Target cards: Projected cost avoidance (30% and 50%), unplanned failure baseline, safety stock reduction target, reactive/proactive target
- Actual cards: Current reactive ratio, total maintenance actions, avg downtime hours
- HPU_10 synthetic vs mineral oil anomaly rate comparison (bar chart)
- Repair cost per machine (bar chart)
- Maintenance cost variance by machine (bar chart)
- Current maintenance strategy split (donut chart)
- Downtime hours by failure mode (clustered bar chart)
- Priority alignment — reactive events vs maintenance priority (bar chart)
- Cumulative repair cost over time (line chart)

---

## Key Findings

- **Pump wear** is the most critical failure mode — 3 occurrences, $28K average repair cost, responsible for over 50 hours of cumulative downtime
- **HPU_08** is the highest-risk machine in the fleet — 23% anomaly rate, $30K repair cost, and only 2 preventive maintenance actions in the period
- **Pressure** is the earliest warning sensor — declining from ~135 bar to ~107 bar as RUL approaches zero, deviating before temperature and flow
- **Contamination** is uniquely identifiable by vibration — reaching 1.6g compared to 0.1–0.3g for all other failure modes
- **Seals** were replaced 18 times across the fleet — the most frequently replaced component, suggesting systemic degradation
- **HPU_10** (synthetic fluid) recorded 0% anomaly rate and zero failures — compared to a 16% average anomaly rate for mineral oil machines
- **Current reactive ratio is 27%** — above the 20% business target, indicating room for improvement in proactive scheduling
- **Projected cost avoidance** of $55K–$92K is achievable based on a 30–50% downtime reduction benchmark

---

## How to Use This Repository

### Setting Up the Database

1. Install PostgreSQL and pgAdmin 4
2. Create a database named `bosch_maintenance`
3. Run the SQL scripts in order:
   ```
   01_create_tables.sql
   02_data_exploration.sql
   03_data_cleaning_view.sql
   04_hourly_aggregation_view.sql
   ```
4. Import each CSV file into its corresponding table using pgAdmin's Import/Export tool (Header: ON, Format: CSV, Delimiter: `,`)

### Connecting Power BI

1. Install the Devart ODBC Driver for PostgreSQL
2. Open `Bosch_Rexroth_AG_Dashboard.pbix` in Power BI Desktop
3. Update the data source credentials to point to your local PostgreSQL instance (`localhost`, database: `bosch_maintenance`)
4. Refresh the dataset

---

## Author

**David Osoba**
Data Analyst | Amdari Work Experience Programme
[GitHub Profile](https://github.com/Davidosoba)

---

## Acknowledgements

Project brief and dataset provided by **Amdari** as part of their Work Experience Programme.
The machine learning component of this project was developed by a separate collaborative team.
