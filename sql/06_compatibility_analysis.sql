-- Audio Plugin QA Data Analysis
-- File: 06_compatibility_analysis.sql
--
-- Run this AFTER 03_data_cleaning.sql.
-- These queries compare failure rates across DAWs, operating systems,
-- and plugin formats. They do not change the data.
--
-- Every result includes the number of tests, the number of failures,
-- and the failure rate. Do not rank a group on the failure count alone.
-- Combination queries keep groups with at least 5 tests.

-- Business Question:
-- Which DAW has the highest failure rate?

-- Approach:
-- Count tests and failures for each DAW.
-- Sort by failure rate so the first row is the highest rate.
-- Also notice which DAW has the most tests. A busy DAW can have more
-- failures without having the worst rate.

SELECT
    daw,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests,
    ROUND(
        100.0 * SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS failure_rate_pct
FROM qa_test_results
GROUP BY daw
ORDER BY failure_rate_pct DESC, failed_tests DESC;

-- Business Question:
-- Which operating system has the highest failure rate?

-- Approach:
-- Same pattern as the DAW query, grouped by operating system.
-- Compare the rate with the number of tests before choosing a follow-up.

SELECT
    operating_system,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests,
    ROUND(
        100.0 * SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS failure_rate_pct
FROM qa_test_results
GROUP BY operating_system
ORDER BY failure_rate_pct DESC, failed_tests DESC;

-- Business Question:
-- Which plugin format has the highest failure rate?

-- Approach:
-- Group by VST3, AU, and AAX.
-- AU tests mostly come from Logic Pro, so the format result and the DAW
-- result need to be read together.

SELECT
    plugin_format,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests,
    ROUND(
        100.0 * SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS failure_rate_pct
FROM qa_test_results
GROUP BY plugin_format
ORDER BY failure_rate_pct DESC, failed_tests DESC;

-- Business Question:
-- Which DAW and plugin-format combination has the most failed tests,
-- and which combination has the highest failure rate?

-- Approach:
-- Group by both DAW and format.
-- HAVING keeps combinations with at least 5 tests.
-- A rate based on 1 or 2 tests can look extreme and is not strong evidence.
-- Sort by failure rate, and use the failed-test count as the tiebreaker.

-- EXPORT: reports/compatibility_analysis.csv
SELECT
    daw,
    plugin_format,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests,
    ROUND(
        100.0 * SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS failure_rate_pct
FROM qa_test_results
GROUP BY daw, plugin_format
HAVING COUNT(*) >= 5
ORDER BY failure_rate_pct DESC, failed_tests DESC;

-- Business Question:
-- Which DAW and operating-system combination fails most often?

-- Approach:
-- Group by DAW and operating system.
-- Again require at least 5 tests before treating the rate as meaningful.
-- Logic Pro only appears on macOS because that DAW is not tested on Windows.

SELECT
    daw,
    operating_system,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests,
    ROUND(
        100.0 * SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS failure_rate_pct
FROM qa_test_results
GROUP BY daw, operating_system
HAVING COUNT(*) >= 5
ORDER BY failure_rate_pct DESC, failed_tests DESC;
