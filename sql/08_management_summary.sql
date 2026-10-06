-- Audio Plugin QA Data Analysis
-- File: 08_management_summary.sql
--
-- Run this AFTER 03_data_cleaning.sql.
-- This file builds one KPI list for a manager who does not read SQL.
-- It does not change the data.
-- The result is saved to reports/management_summary.csv.
--
-- Rates are percentages, not fractions. 83.6 means 83.6 percent.
-- Average Bug Resolution Days includes resolved bugs only.

-- Business Question:
-- What are the headline QA numbers for this period?

-- Approach:
-- Calculate each KPI in its own SELECT.
-- UNION ALL stacks those single-row results into one list.
-- CAST turns every number into text so the column types match.

-- EXPORT: reports/management_summary.csv
SELECT 'Total QA Tests' AS metric, CAST(COUNT(*) AS TEXT) AS value
FROM qa_test_results
UNION ALL
SELECT
    'Passed Tests',
    CAST(SUM(CASE WHEN test_status = 'Pass' THEN 1 ELSE 0 END) AS TEXT)
FROM qa_test_results
UNION ALL
SELECT
    'Failed Tests',
    CAST(SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) AS TEXT)
FROM qa_test_results
UNION ALL
SELECT
    'Overall Pass Rate (%)',
    CAST(ROUND(
        100.0 * SUM(CASE WHEN test_status = 'Pass' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS TEXT)
FROM qa_test_results
UNION ALL
SELECT 'Total Bugs', CAST(COUNT(*) AS TEXT)
FROM bugs
UNION ALL
SELECT 'Open Bugs', CAST(SUM(CASE WHEN bug_status = 'Open' THEN 1 ELSE 0 END) AS TEXT)
FROM bugs
UNION ALL
SELECT
    'In Progress Bugs',
    CAST(SUM(CASE WHEN bug_status = 'In Progress' THEN 1 ELSE 0 END) AS TEXT)
FROM bugs
UNION ALL
SELECT
    'Resolved Bugs',
    CAST(SUM(CASE WHEN bug_status = 'Resolved' THEN 1 ELSE 0 END) AS TEXT)
FROM bugs
UNION ALL
SELECT
    'Unresolved Bugs',
    CAST(SUM(CASE WHEN bug_status IN ('Open', 'In Progress') THEN 1 ELSE 0 END) AS TEXT)
FROM bugs
UNION ALL
SELECT
    'High Severity Bugs',
    CAST(SUM(CASE WHEN severity = 'High' THEN 1 ELSE 0 END) AS TEXT)
FROM bugs
UNION ALL
SELECT
    'Critical Bugs',
    CAST(SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END) AS TEXT)
FROM bugs
UNION ALL
SELECT
    'Average Bug Resolution Days',
    CAST(ROUND(AVG(resolution_days), 1) AS TEXT)
FROM bugs
WHERE bug_status = 'Resolved';
