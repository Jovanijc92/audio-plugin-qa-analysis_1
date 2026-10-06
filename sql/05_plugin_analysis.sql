-- Audio Plugin QA Data Analysis
-- File: 05_plugin_analysis.sql
--
-- Run this AFTER 03_data_cleaning.sql.
-- These queries compare plugins. They do not change the data.
-- The last query is saved to reports/plugin_performance.csv.

-- Business Question:
-- How many tests were performed for each plugin?

-- Approach:
-- Join plugins to tests and count the tests.
-- Keep the version in the grouping so the two Northwind Synth rows stay separate.

SELECT
    p.plugin_name,
    p.plugin_version,
    COUNT(*) AS total_tests
FROM plugins AS p
INNER JOIN qa_test_results AS t ON p.plugin_id = t.plugin_id
GROUP BY p.plugin_id, p.plugin_name, p.plugin_version
ORDER BY p.plugin_name, p.plugin_version;

-- Business Question:
-- How many tests failed for each plugin?

-- Approach:
-- Use a CASE expression inside SUM to count only the failed tests.

SELECT
    p.plugin_name,
    p.plugin_version,
    SUM(CASE WHEN t.test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests
FROM plugins AS p
INNER JOIN qa_test_results AS t ON p.plugin_id = t.plugin_id
GROUP BY p.plugin_id, p.plugin_name, p.plugin_version
ORDER BY failed_tests DESC, p.plugin_name;

-- Business Question:
-- What is each plugin's failure rate?

-- Approach:
-- Count all tests and the failed tests.
-- Failure rate = failed tests / total tests.
-- Show all three numbers together. A high rate on a small test count is a
-- weaker signal than the same rate on a large test count.

SELECT
    p.plugin_name,
    p.plugin_version,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN t.test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests,
    ROUND(
        100.0 * SUM(CASE WHEN t.test_status = 'Fail' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS failure_rate_pct
FROM plugins AS p
INNER JOIN qa_test_results AS t ON p.plugin_id = t.plugin_id
GROUP BY p.plugin_id, p.plugin_name, p.plugin_version
ORDER BY failure_rate_pct DESC, failed_tests DESC;

-- Business Question:
-- How do the two Northwind Synth versions compare?

-- Approach:
-- Filter to that plugin name, then group by version.
-- This is a follow-up to the failure-rate query, which showed both versions.

SELECT
    p.plugin_name,
    p.plugin_version,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN t.test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests,
    ROUND(
        100.0 * SUM(CASE WHEN t.test_status = 'Fail' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS failure_rate_pct
FROM plugins AS p
INNER JOIN qa_test_results AS t ON p.plugin_id = t.plugin_id
WHERE p.plugin_name = 'Northwind Synth'
GROUP BY p.plugin_id, p.plugin_name, p.plugin_version
ORDER BY p.plugin_version;

-- Business Question:
-- How many bugs were reported for each plugin?

-- Approach:
-- LEFT JOIN starts from plugins, so a plugin with no bugs would still appear.
-- COUNT(bug_id) ignores the empty side of a left join. COUNT(*) would not.

SELECT
    p.plugin_name,
    p.plugin_version,
    COUNT(b.bug_id) AS total_bugs
FROM plugins AS p
LEFT JOIN bugs AS b ON p.plugin_id = b.plugin_id
GROUP BY p.plugin_id, p.plugin_name, p.plugin_version
ORDER BY total_bugs DESC, p.plugin_name;

-- Business Question:
-- Which plugins have High severity bugs?

-- Approach:
-- Join bugs to plugins and keep severity = High.
-- DISTINCT removes repeated plugin names when a plugin has more than one.

SELECT DISTINCT
    p.plugin_name,
    p.plugin_version
FROM bugs AS b
INNER JOIN plugins AS p ON b.plugin_id = p.plugin_id
WHERE b.severity = 'High'
ORDER BY p.plugin_name, p.plugin_version;

-- Business Question:
-- Which plugins have Critical bugs?

-- Approach:
-- Same pattern as the High severity query, filtered to Critical.

SELECT DISTINCT
    p.plugin_name,
    p.plugin_version
FROM bugs AS b
INNER JOIN plugins AS p ON b.plugin_id = p.plugin_id
WHERE b.severity = 'Critical'
ORDER BY p.plugin_name, p.plugin_version;

-- Business Question:
-- Which plugins have unresolved bugs?

-- Approach:
-- Unresolved means Open or In Progress.
-- Count those bugs by plugin so the result is not just a long bug list.

SELECT
    p.plugin_name,
    p.plugin_version,
    SUM(CASE WHEN b.bug_status = 'Open' THEN 1 ELSE 0 END) AS open_bugs,
    SUM(CASE WHEN b.bug_status = 'In Progress' THEN 1 ELSE 0 END) AS in_progress_bugs
FROM bugs AS b
INNER JOIN plugins AS p ON b.plugin_id = p.plugin_id
WHERE b.bug_status IN ('Open', 'In Progress')
GROUP BY p.plugin_id, p.plugin_name, p.plugin_version
ORDER BY open_bugs DESC, in_progress_bugs DESC, p.plugin_name;

-- Business Question:
-- Which plugins should QA look at first?

-- Approach:
-- Build two summaries with CTEs, then join them to the plugin list.
-- test_stats holds test counts. bug_stats holds bug counts.
-- A plugin with tests but no bugs still appears because the bug join is a LEFT JOIN.
-- COALESCE turns a missing bug count into 0.

-- EXPORT: reports/plugin_performance.csv
WITH test_stats AS (
    SELECT
        plugin_id,
        COUNT(*) AS total_tests,
        SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests
    FROM qa_test_results
    GROUP BY plugin_id
),
bug_stats AS (
    SELECT
        plugin_id,
        COUNT(*) AS total_bugs,
        SUM(CASE WHEN bug_status = 'Open' THEN 1 ELSE 0 END) AS open_bugs,
        SUM(CASE WHEN severity = 'High' THEN 1 ELSE 0 END) AS high_severity_bugs,
        SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END) AS critical_bugs
    FROM bugs
    GROUP BY plugin_id
)
SELECT
    p.plugin_name || ' (' || p.plugin_version || ')' AS plugin_name,
    t.total_tests,
    t.failed_tests,
    ROUND(100.0 * t.failed_tests / t.total_tests, 1) AS failure_rate_pct,
    COALESCE(b.total_bugs, 0) AS total_bugs,
    COALESCE(b.open_bugs, 0) AS open_bugs,
    COALESCE(b.high_severity_bugs, 0) AS high_severity_bugs,
    COALESCE(b.critical_bugs, 0) AS critical_bugs
FROM plugins AS p
INNER JOIN test_stats AS t ON p.plugin_id = t.plugin_id
LEFT JOIN bug_stats AS b ON p.plugin_id = b.plugin_id
ORDER BY failure_rate_pct DESC, t.failed_tests DESC;
