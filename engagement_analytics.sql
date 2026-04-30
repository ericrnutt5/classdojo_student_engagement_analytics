-- =====================================
-- 1. Create database
-- =====================================

CREATE DATABASE IF NOT EXISTS engagement_analytics;
USE engagement_analytics;


-- =====================================
-- 2. Create data tables
-- =====================================

DROP TABLE IF EXISTS students;
CREATE TABLE students (
  student_id VARCHAR(10) PRIMARY KEY,
  student_name VARCHAR(50),
  classroom_id VARCHAR(10),
  grade_level INT,
  created_at DATE
);


DROP TABLE IF EXISTS student_events;
CREATE TABLE student_events (
  event_id VARCHAR(10) PRIMARY KEY,
  student_id VARCHAR(10),
  event_type VARCHAR(30),
  event_value INT,
  event_at DATETIME
);


DROP TABLE IF EXISTS parent_views;
CREATE TABLE parent_views (
  view_id VARCHAR(10) PRIMARY KEY,
  student_id VARCHAR(10),
  viewed_at DATETIME
);


-- =====================================
-- 3. Insert data into data tables
-- =====================================

INSERT INTO students
SELECT
  CONCAT('s', n),
  CONCAT('Student ', n),
  CONCAT('c', FLOOR(1 + (n % 5))),
  FLOOR(3 + (n % 3)),
  '2025-01-01'
FROM (
  SELECT @row := @row + 1 AS n
  FROM information_schema.columns, (SELECT @row := 0) r
  LIMIT 30
) x;

INSERT INTO student_events
SELECT
  CONCAT('e', n),
  CONCAT('s', FLOOR(1 + RAND() * 30)),
  ELT(FLOOR(1 + RAND()*2), 'points', 'participation'),
  FLOOR(1 + RAND()*10),
  DATE_ADD('2025-02-01 08:00:00', INTERVAL FLOOR(RAND()*10) DAY)
FROM (
  SELECT @row := @row + 1 AS n
  FROM information_schema.columns, (SELECT @row := 0) r
  LIMIT 400
) x;

INSERT INTO parent_views 
SELECT
  CONCAT('v', n),
  CONCAT('s', FLOOR(1 + RAND() * 30)),
  DATE_ADD('2025-02-01 18:00:00', INTERVAL FLOOR(RAND()*10) DAY)
FROM (
  SELECT @row := @row + 1 AS n
  FROM information_schema.columns, (SELECT @row := 0) r
  LIMIT 200
) x;


-- ====================================
-- 4. Validation
-- ====================================

SELECT * FROM students;
SELECT * FROM student_events;
SELECT * FROM parent_views;
SELECT COUNT(*) FROM student_events;
SELECT COUNT(*) FROM parent_views;


-- ====================================
-- 5. Create Student Engagement Table
-- ====================================

DROP TABLE IF EXISTS fct_student_daily_engagement;
CREATE TABLE fct_student_daily_engagement (
  student_id VARCHAR(10),
  activity_date DATE,
  activity_count INT,
  total_points INT,
  parent_views INT,
  engagement_score DECIMAL(10,2)
);

INSERT INTO fct_student_daily_engagement

WITH event_agg AS (
  SELECT
    student_id,
    DATE(event_at) AS activity_date,
    COUNT(*) AS activity_count,
    SUM(event_value) AS total_points
  FROM student_events
  GROUP BY student_id, DATE(event_at)
),

view_agg AS (
  SELECT
    student_id,
    DATE(viewed_at) AS activity_date,
    COUNT(*) AS parent_views
  FROM parent_views
  GROUP BY student_id, DATE(viewed_at)
)

SELECT
    e.student_id,
    e.activity_date,
    e.activity_count,
    e.total_points,
    COALESCE(v.parent_views, 0) AS parent_views,
    -- Engagement Score
    (e.activity_count * 0.5)
    + (e.total_points * 0.3)
    + (COALESCE(v.parent_views, 0) * 0.2) AS engagement_score
  FROM event_agg e
  LEFT JOIN view_agg v
    ON e.student_id = v.student_id
   AND e.activity_date = v.activity_date;

SELECT * FROM fct_student_daily_engagement;


-- ====================================
-- 6. Data Quality Checks
-- ====================================

-- ==================================================
-- 6.1 Grain integrity (NO duplicates allowed)
-- Ensures your fact table is truly student × day
-- Expected Result: 0 rows
-- ==================================================
SELECT
  student_id,
  activity_date,
  COUNT(*) AS row_count
FROM fct_student_daily_engagement
GROUP BY student_id, activity_date
HAVING row_count > 1;


-- ==================================================
-- 6.2 Orphaned records (must not exist)
-- Every fact row should map to a real student
-- Expected Result: 0 rows
-- ==================================================
SELECT f.*
FROM fct_student_daily_engagement f
LEFT JOIN students s
  ON f.student_id = s.student_id
WHERE s.student_id IS NULL;


-- ==================================================
-- 6.3 Missing engagement signals
-- All data should be complete; 
-- test data has at least one activity for every student
-- Expected Result: 0 rows
-- ==================================================
SELECT *
FROM fct_student_daily_engagement
WHERE activity_count IS NULL
   OR total_points IS NULL;


-- ==================================================
-- 6.4 Score sanity check
-- Engagement score should never be negative
-- Expected Result: 0 rows
-- ==================================================
SELECT *
FROM fct_student_daily_engagement
WHERE engagement_score < 0;


-- ====================================
-- 7. Top Improving Students
-- ====================================

WITH ranked_days AS (
  SELECT
    student_id,
    activity_date,
    engagement_score,
    NTILE(2) OVER (
      PARTITION BY student_id
      ORDER BY activity_date
    ) AS time_bucket
  FROM fct_student_daily_engagement
),

bucketed AS (
  SELECT
    student_id,
    time_bucket,
    AVG(engagement_score) AS avg_score
  FROM ranked_days
  GROUP BY student_id, time_bucket
),

pivoted AS (
  SELECT
    student_id,
    MAX(CASE WHEN time_bucket = 1 THEN avg_score END) AS early_avg,
    MAX(CASE WHEN time_bucket = 2 THEN avg_score END) AS late_avg
  FROM bucketed
  GROUP BY student_id
)

SELECT
  student_id,
  early_avg,
  late_avg,
  (late_avg - early_avg) AS improvement_score
FROM pivoted
ORDER BY improvement_score DESC;
