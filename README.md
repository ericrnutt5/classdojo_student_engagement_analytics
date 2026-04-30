# Student Engagement Analytics Layer

## Problem Statement

Educational platforms need a reliable way to measure student engagement across both behavioral activity and family visibility. Raw event data is fragmented across multiple sources, making consistent reporting difficult.

This project builds a simplified analytics layer that models student engagement at a daily grain.

---

## Data Model Overview

The system consists of three source tables:

- `students` → student identity and class assignment  
- `student_events` → behavioral activity (points, participation)  
- `parent_views` → family engagement signals  

These are transformed into a single fact table:

> `fct_student_daily_engagement`

**Grain:** `student_id + activity_date`

---

## Project Files

All SQL used to create and populate this analytics layer is stored in:

- `engagement_analytics.sql`

This file contains:
- Table creation statements
- Data generation and inserts
- Fact table modeling logic (`fct_student_daily_engagement`)
- Data quality validation queries

---

## Final Fact Table

Each row represents a student's daily engagement profile:

- `activity_count` → number of student interactions  
- `total_points` → total engagement value  
- `parent_views` → family visibility signal  
- `engagement_score` → weighted composite metric  

---

## Metric Design: Engagement Score

Engagement is defined as a weighted composite:

```sql
engagement_score =
  0.5 * activity_count +
  0.3 * total_points +
  0.2 * parent_views
```
---

## Rationale
- Activity_count reflects behavioral participation
- Total_points reflects depth of engagement
- Parent_views reflects external reinforcement

This balances student behavior and family visibility, both critical signals in education engagement systems.

---

## Data Quality Controls

To ensure reliability, the following checks were implemented:

- Grain validation: ensures one record per student per day
- Referential integrity: ensures all records map to valid students
- Completeness checks: ensures no missing activity or scoring fields
- Metric sanity checks: ensures engagement score is non-negative
- Distribution review: validates expected variability across students

---

## Key Design Decisions
- Chose a daily grain for interpretability and trend analysis
- Used a simple weighted model for transparency and explainability
- Prioritized query simplicity over normalization complexity
- Designed for extensibility (can support additional signals like assignments, messaging, etc.)

---

## Future Improvements
- Incorporate classroom-level aggregation metrics
- Add time-decay weighting for engagement recency
- Introduce anomaly detection for engagement drops
- Extend model to support real-time streaming data
- Replace static weights with learned parameters (ML-based scoring)
