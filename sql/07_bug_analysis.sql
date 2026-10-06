-- Audio Plugin QA Data Analysis
-- File: 07_bug_analysis.sql
--
-- Run this AFTER 03_data_cleaning.sql.
-- These queries describe the bug backlog. They do not change the data.
-- The category summary is saved to reports/bug_summary.csv.

-- Business Question:
-- What are the most common bug categories?

-- Approach:
-- Count bugs in each category and sort the largest group first.

SELECT
    bug_category,
    COUNT(*) AS bug_count
FROM bugs
GROUP BY bug_category
ORDER BY bug_count DESC, bug_category;

-- Business Question:
-- How many bugs exist at each severity level?

-- Approach:
-- Count bugs by severity.
-- The CASE expression in ORDER BY puts Critical first and Low last.

SELECT
    severity,
    COUNT(*) AS bug_count
FROM bugs
GROUP BY severity
ORDER BY CASE severity
    WHEN 'Critical' THEN 1
    WHEN 'High' THEN 2
    WHEN 'Medium' THEN 3
    WHEN 'Low' THEN 4
    ELSE 5
END;

-- Business Question:
-- How many bugs are Open, In Progress, or Resolved?

-- Approach:
-- Count bugs by status.
-- Open and In Progress are both unfinished. Resolved is finished.

SELECT
    bug_status,
    COUNT(*) AS bug_count
FROM bugs
GROUP BY bug_status
ORDER BY CASE bug_status
    WHEN 'Open' THEN 1
    WHEN 'In Progress' THEN 2
    WHEN 'Resolved' THEN 3
    ELSE 4
END;

-- Business Question:
-- What is the average resolution time for resolved bugs?

-- Approach:
-- Average resolution_days for Resolved bugs only.
-- Open and In Progress bugs have a blank day count, and AVG would skip
-- those blanks anyway. The WHERE clause makes the filter obvious.

SELECT
    COUNT(*) AS resolved_bugs,
    ROUND(AVG(resolution_days), 1) AS average_resolution_days,
    MIN(resolution_days) AS fastest_resolution_days,
    MAX(resolution_days) AS slowest_resolution_days
FROM bugs
WHERE bug_status = 'Resolved';

-- Business Question:
-- Which bug categories take the longest to resolve?

-- Approach:
-- Average the resolution time for resolved bugs in each category.
-- Show the number of resolved bugs beside the average.
-- A category with one or two resolved bugs can have a high average by chance.

SELECT
    bug_category,
    COUNT(*) AS resolved_bugs,
    ROUND(AVG(resolution_days), 1) AS average_resolution_days
FROM bugs
WHERE bug_status = 'Resolved'
GROUP BY bug_category
ORDER BY average_resolution_days DESC, resolved_bugs DESC;

-- Business Question:
-- Which categories look slowest when we ignore very small groups?

-- Approach:
-- Same average as the query above.
-- HAVING keeps categories with at least 3 resolved bugs.
-- Three is still a small sample. It only removes the one-off averages.

SELECT
    bug_category,
    COUNT(*) AS resolved_bugs,
    ROUND(AVG(resolution_days), 1) AS average_resolution_days
FROM bugs
WHERE bug_status = 'Resolved'
GROUP BY bug_category
HAVING COUNT(*) >= 3
ORDER BY average_resolution_days DESC;

-- Business Question:
-- Do higher-severity bugs take longer to resolve?

-- Approach:
-- Average resolution_days by severity for resolved bugs.
-- Read the count before comparing Critical with Low. Critical is uncommon,
-- so its average may be based on very few bugs.

SELECT
    severity,
    COUNT(*) AS resolved_bugs,
    ROUND(AVG(resolution_days), 1) AS average_resolution_days
FROM bugs
WHERE bug_status = 'Resolved'
GROUP BY severity
ORDER BY CASE severity
    WHEN 'Low' THEN 1
    WHEN 'Medium' THEN 2
    WHEN 'High' THEN 3
    WHEN 'Critical' THEN 4
    ELSE 5
END;

-- Business Question:
-- Which plugins currently have unresolved High or Critical bugs?

-- Approach:
-- Join bugs to plugins so the plugin name is visible.
-- Keep bugs that are not resolved and are High or Critical.
-- This is the short list a QA lead can act on.

SELECT
    p.plugin_name,
    p.plugin_version,
    b.bug_id,
    b.bug_category,
    b.severity,
    b.bug_status,
    b.date_reported
FROM bugs AS b
INNER JOIN plugins AS p ON b.plugin_id = p.plugin_id
WHERE b.bug_status IN ('Open', 'In Progress')
  AND b.severity IN ('High', 'Critical')
ORDER BY
    CASE b.severity
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        ELSE 3
    END,
    p.plugin_name,
    b.date_reported;

-- Business Question:
-- What percentage of bugs have been resolved?

-- Approach:
-- Divide resolved bugs by all bugs.
-- The other two status counts are included so the three statuses add up
-- to the total.

SELECT
    COUNT(*) AS total_bugs,
    SUM(CASE WHEN bug_status = 'Resolved' THEN 1 ELSE 0 END) AS resolved_bugs,
    SUM(CASE WHEN bug_status = 'In Progress' THEN 1 ELSE 0 END) AS in_progress_bugs,
    SUM(CASE WHEN bug_status = 'Open' THEN 1 ELSE 0 END) AS open_bugs,
    ROUND(
        100.0 * SUM(CASE WHEN bug_status = 'Resolved' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS resolved_pct
FROM bugs;

-- Business Question:
-- How many failed tests never became a bug ticket?

-- Approach:
-- A subquery collects every test_id that already has a bug.
-- The outer query counts failed tests that are not in that list.
-- Not every failure is logged as a bug, so bug counts will be lower than
-- failure counts. That is expected in this dataset.

SELECT COUNT(*) AS failed_tests_without_a_bug
FROM qa_test_results
WHERE test_status = 'Fail'
  AND test_id NOT IN (SELECT test_id FROM bugs);

-- Business Question:
-- What does the bug backlog look like by category?

-- Approach:
-- One row per category, with the count, open bugs, resolved bugs,
-- serious bugs, and the average resolution time.
-- The average uses only resolved bugs. Blank day counts are ignored by AVG.

-- EXPORT: reports/bug_summary.csv
SELECT
    bug_category,
    COUNT(*) AS bug_count,
    SUM(CASE WHEN bug_status = 'Open' THEN 1 ELSE 0 END) AS open_bugs,
    SUM(CASE WHEN bug_status = 'Resolved' THEN 1 ELSE 0 END) AS resolved_bugs,
    SUM(CASE WHEN severity = 'High' THEN 1 ELSE 0 END) AS high_severity_bugs,
    SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END) AS critical_bugs,
    ROUND(AVG(CASE WHEN bug_status = 'Resolved' THEN resolution_days END), 1)
        AS avg_resolution_days
FROM bugs
GROUP BY bug_category
ORDER BY bug_count DESC, bug_category;
