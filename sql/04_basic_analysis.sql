-- Audio Plugin QA Data Analysis
-- File: 04_basic_analysis.sql
--
-- Run this AFTER 03_data_cleaning.sql.
-- These queries answer the first, simplest questions about the QA period.
-- This file does not change the data.
--
-- The QA period in this dataset is 1 October 2025 through 31 March 2026.

-- Business Question:
-- How many QA tests were performed?

-- Approach:
-- Count every test row.
-- COUNT(*) includes the five tests whose duration is blank.
-- COUNT(test_duration_minutes) would skip those rows, so it is not used here.

SELECT COUNT(*) AS total_tests
FROM qa_test_results;

-- Business Question:
-- How many tests passed?

-- Approach:
-- Count rows whose cleaned status is Pass.

SELECT COUNT(*) AS passed_tests
FROM qa_test_results
WHERE test_status = 'Pass';

-- Business Question:
-- How many tests failed?

-- Approach:
-- Count rows whose cleaned status is Fail.

SELECT COUNT(*) AS failed_tests
FROM qa_test_results
WHERE test_status = 'Fail';

-- Business Question:
-- What is the overall pass rate?

-- Approach:
-- Divide passed tests by all tests.
-- Multiply by 100.0 before dividing so SQLite does not drop the decimal.

SELECT
    COUNT(*) AS total_tests,
    SUM(CASE WHEN test_status = 'Pass' THEN 1 ELSE 0 END) AS passed_tests,
    SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests,
    ROUND(
        100.0 * SUM(CASE WHEN test_status = 'Pass' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS pass_rate_pct
FROM qa_test_results;

-- Business Question:
-- How many tests were performed for each plugin?

-- Approach:
-- Join tests to plugins so the result shows the plugin name and version.
-- Group by plugin_id, not just the name, because Northwind Synth has two versions.

SELECT
    p.plugin_name,
    p.plugin_version,
    COUNT(*) AS total_tests
FROM plugins AS p
INNER JOIN qa_test_results AS t ON p.plugin_id = t.plugin_id
GROUP BY p.plugin_id, p.plugin_name, p.plugin_version
ORDER BY total_tests DESC, p.plugin_name;

-- Business Question:
-- How many tests were performed for each DAW?

-- Approach:
-- Group the cleaned test rows by DAW and count them.

SELECT
    daw,
    COUNT(*) AS total_tests
FROM qa_test_results
GROUP BY daw
ORDER BY total_tests DESC;

-- Business Question:
-- How many tests were performed for each operating system?

-- Approach:
-- Group by operating system and count the tests.

SELECT
    operating_system,
    COUNT(*) AS total_tests
FROM qa_test_results
GROUP BY operating_system
ORDER BY total_tests DESC;

-- Business Question:
-- How many tests were performed for each plugin format?

-- Approach:
-- Group by plugin format and count the tests.

SELECT
    plugin_format,
    COUNT(*) AS total_tests
FROM qa_test_results
GROUP BY plugin_format
ORDER BY total_tests DESC;

-- Business Question:
-- How many bugs were reported?

-- Approach:
-- Count every row in the bugs table.

SELECT COUNT(*) AS total_bugs
FROM bugs;

-- Business Question:
-- How many bugs are currently open?

-- Approach:
-- Count bugs whose status is Open.
-- In Progress is a separate status and is not included in this count.

SELECT COUNT(*) AS open_bugs
FROM bugs
WHERE bug_status = 'Open';

-- Business Question:
-- How often does each test category fail?

-- Approach:
-- Count all tests and the failed tests in each category.
-- Show the failure rate beside the counts so a small category is not
-- judged on the percentage alone.

SELECT
    test_category,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests,
    ROUND(
        100.0 * SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS failure_rate_pct
FROM qa_test_results
GROUP BY test_category
ORDER BY failure_rate_pct DESC, failed_tests DESC;

-- Business Question:
-- How long does a test usually take?

-- Approach:
-- AVG skips blank durations, which is what we want.
-- The COUNT columns show that 5 durations are blank and were not guessed.

SELECT
    COUNT(*) AS tests_including_blank_duration,
    COUNT(test_duration_minutes) AS tests_with_duration,
    ROUND(AVG(test_duration_minutes), 1) AS average_duration_minutes,
    MIN(test_duration_minutes) AS shortest_test_minutes,
    MAX(test_duration_minutes) AS longest_test_minutes
FROM qa_test_results;
