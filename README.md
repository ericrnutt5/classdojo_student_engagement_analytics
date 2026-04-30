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

`fct_student_daily_engagement`

**Grain:** `student_id + activity_date`

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
