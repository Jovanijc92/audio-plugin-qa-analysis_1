-- Audio Plugin QA Data Analysis
-- File: 02_data_quality_checks.sql
--
-- Run this BEFORE 03_data_cleaning.sql.
-- These queries only read the data. They do not change anything.
--
-- If the database has already been cleaned, most of these checks should
-- come back empty or show only the nulls we intentionally kept.

-- Business Question:
-- Are any required IDs missing?

-- Approach:
-- Count blank plugin, test, and bug IDs.
-- A blank ID would mean the row cannot be joined reliably.

SELECT 'plugins.plugin_id' AS column_name, COUNT(*) AS null_count
FROM plugins
WHERE plugin_id IS NULL
UNION ALL
SELECT 'qa_test_results.test_id', COUNT(*)
FROM qa_test_results
WHERE test_id IS NULL
UNION ALL
SELECT 'qa_test_results.plugin_id', COUNT(*)
FROM qa_test_results
WHERE plugin_id IS NULL
UNION ALL
SELECT 'bugs.bug_id', COUNT(*)
FROM bugs
WHERE bug_id IS NULL
UNION ALL
SELECT 'bugs.test_id', COUNT(*)
FROM bugs
WHERE test_id IS NULL
UNION ALL
SELECT 'bugs.plugin_id', COUNT(*)
FROM bugs
WHERE plugin_id IS NULL;

-- Business Question:
-- How many tests are missing a duration?

-- Approach:
-- Count blank test_duration_minutes values.
-- Duration is optional here, so these blanks are reviewed and then left blank.
-- They should not be filled with a guess.

SELECT COUNT(*) AS tests_missing_duration
FROM qa_test_results
WHERE test_duration_minutes IS NULL;

-- Business Question:
-- Which resolution dates are blank, and is that a problem?

-- Approach:
-- Blank resolution dates are normal for bugs that are not resolved.
-- This query only counts them. The next queries look for the suspicious cases.

SELECT bug_status, COUNT(*) AS bugs_missing_resolution_date
FROM bugs
WHERE date_resolved IS NULL
GROUP BY bug_status
ORDER BY bug_status;

-- Business Question:
-- Did any resolved bug lose its resolution date or day count?

-- Approach:
-- A resolved bug should have both a resolution date and a day count.
-- Rows returned here need to be fixed before the average is calculated.

SELECT bug_id, bug_status, date_reported, date_resolved, resolution_days
FROM bugs
WHERE bug_status = 'Resolved'
  AND (date_resolved IS NULL OR resolution_days IS NULL)
ORDER BY bug_id;

-- Business Question:
-- Did any unresolved bug get a resolution date by mistake?

-- Approach:
-- Open and In Progress bugs should not have a resolution date.
-- The status check below also catches values such as "open".

SELECT bug_id, bug_status, date_resolved, resolution_days
FROM bugs
WHERE LOWER(bug_status) IN ('open', 'in progress')
  AND (date_resolved IS NOT NULL OR resolution_days IS NOT NULL)
ORDER BY bug_id;

-- Business Question:
-- Are there duplicate QA tests?

-- Approach:
-- test_id is unique, so a second copy usually has a new ID and the same details.
-- Group by the test details and keep groups that appear more than once.

SELECT
    plugin_id,
    test_date,
    operating_system,
    daw,
    plugin_format,
    test_category,
    test_status,
    test_duration_minutes,
    COUNT(*) AS duplicate_rows
FROM qa_test_results
GROUP BY
    plugin_id,
    test_date,
    operating_system,
    daw,
    plugin_format,
    test_category,
    test_status,
    test_duration_minutes
HAVING COUNT(*) > 1;

-- Business Question:
-- Are operating system names consistent?

-- Approach:
-- List each distinct value and how often it appears.
-- "Windows11" is the same OS as "Windows 11", but SQL treats them as different.

SELECT operating_system, COUNT(*) AS test_count
FROM qa_test_results
GROUP BY operating_system
ORDER BY operating_system;

-- Business Question:
-- Are DAW names consistent?

-- Approach:
-- List each distinct DAW value.
-- Look for extra spaces, lowercase names, and other variants of the same DAW.

SELECT daw, COUNT(*) AS test_count
FROM qa_test_results
GROUP BY daw
ORDER BY daw;

-- Business Question:
-- Are plugin format names consistent?

-- Approach:
-- List each distinct format.
-- "vst3" and "VST3" should be one format.

SELECT plugin_format, COUNT(*) AS test_count
FROM qa_test_results
GROUP BY plugin_format
ORDER BY plugin_format;

-- Business Question:
-- Are test statuses limited to Pass and Fail?

-- Approach:
-- List each distinct status.
-- "pass" and "FAIL" need to be standardized before pass-rate math.

SELECT test_status, COUNT(*) AS test_count
FROM qa_test_results
GROUP BY test_status
ORDER BY test_status;

-- Business Question:
-- Are severity values limited to Low, Medium, High, and Critical?

-- Approach:
-- List each distinct severity.
-- A lowercase value such as "medium" would be left out of an exact-match count.

SELECT severity, COUNT(*) AS bug_count
FROM bugs
GROUP BY severity
ORDER BY severity;

-- Business Question:
-- Are bug statuses limited to Open, In Progress, and Resolved?

-- Approach:
-- List each distinct status and look for capitalization differences.

SELECT bug_status, COUNT(*) AS bug_count
FROM bugs
GROUP BY bug_status
ORDER BY bug_status;

-- Business Question:
-- Does every bug point at the same plugin as its test?

-- Approach:
-- Join bugs to tests on test_id and compare plugin_id.
-- A mismatch would mean the bug was attached to the wrong plugin.

SELECT COUNT(*) AS plugin_id_mismatches
FROM bugs AS b
INNER JOIN qa_test_results AS t ON b.test_id = t.test_id
WHERE b.plugin_id <> t.plugin_id;

-- Business Question:
-- Does every test and bug point at a real plugin?

-- Approach:
-- LEFT JOIN keeps rows that do not find a match.
-- Those unmatched rows have a null plugin name.

SELECT COUNT(*) AS tests_with_unknown_plugin
FROM qa_test_results AS t
LEFT JOIN plugins AS p ON t.plugin_id = p.plugin_id
WHERE p.plugin_id IS NULL;

SELECT COUNT(*) AS bugs_with_unknown_plugin
FROM bugs AS b
LEFT JOIN plugins AS p ON b.plugin_id = p.plugin_id
WHERE p.plugin_id IS NULL;
