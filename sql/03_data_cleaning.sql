-- Audio Plugin QA Data Analysis
-- File: 03_data_cleaning.sql
--
-- Run this AFTER 02_data_quality_checks.sql and BEFORE the analysis files.
-- Each update below fixes one problem found by those checks.
-- The script is safe to run a second time. After the first run, the
-- updates simply change zero rows.
--
-- Five blank test durations are left blank on purpose. Duration was not
-- recorded for those tests, and filling it in would invent data.

PRAGMA foreign_keys = ON;

-- Problem found:
-- A few DAW names had extra spaces, such as " Pro Tools ".

-- What this changes:
-- Removes spaces at the start and end of the text columns used in grouping.

-- Why:
-- " Pro Tools " and "Pro Tools" would otherwise look like two DAWs.

UPDATE qa_test_results
SET
    operating_system = TRIM(operating_system),
    daw = TRIM(daw),
    plugin_format = TRIM(plugin_format),
    test_category = TRIM(test_category),
    test_status = TRIM(test_status)
WHERE operating_system <> TRIM(operating_system)
   OR daw <> TRIM(daw)
   OR plugin_format <> TRIM(plugin_format)
   OR test_category <> TRIM(test_category)
   OR test_status <> TRIM(test_status);

-- Problem found:
-- Some Windows 11 rows were exported as "Windows11".

-- What this changes:
-- Stores those rows as "Windows 11".

-- Why:
-- Reports should use the same operating-system name the QA team uses.

UPDATE qa_test_results
SET operating_system = 'Windows 11'
WHERE operating_system = 'Windows11';

-- Problem found:
-- Some REAPER rows were exported as "reaper".

-- What this changes:
-- Stores those rows as "REAPER".

-- Why:
-- The pass/fail rate by DAW would split one DAW into two groups.

UPDATE qa_test_results
SET daw = 'REAPER'
WHERE LOWER(daw) = 'reaper';

-- Problem found:
-- Test status used mixed capitalization: "pass" and "FAIL".

-- What this changes:
-- Stores the status as "Pass" or "Fail".

-- Why:
-- The pass-rate queries match the exact words "Pass" and "Fail".

UPDATE qa_test_results
SET test_status = CASE LOWER(test_status)
    WHEN 'pass' THEN 'Pass'
    WHEN 'fail' THEN 'Fail'
    ELSE test_status
END
WHERE LOWER(test_status) IN ('pass', 'fail')
  AND test_status NOT IN ('Pass', 'Fail');

-- Problem found:
-- Some VST3 rows were exported as "vst3".

-- What this changes:
-- Stores those rows as "VST3".

-- Why:
-- Format comparisons should not treat capitalization as a different format.

UPDATE qa_test_results
SET plugin_format = 'VST3'
WHERE UPPER(plugin_format) = 'VST3'
  AND plugin_format <> 'VST3';

-- Problem found:
-- One severity value was stored as "medium".

-- What this changes:
-- Stores severity as Low, Medium, High, or Critical.

-- Why:
-- Counts by severity use those four exact words.

UPDATE bugs
SET severity = CASE LOWER(severity)
    WHEN 'low' THEN 'Low'
    WHEN 'medium' THEN 'Medium'
    WHEN 'high' THEN 'High'
    WHEN 'critical' THEN 'Critical'
    ELSE severity
END
WHERE severity NOT IN ('Low', 'Medium', 'High', 'Critical');

-- Problem found:
-- One bug status was stored as "open".

-- What this changes:
-- Stores the status as Open, In Progress, or Resolved.

-- Why:
-- This has to happen before the next update, which looks for the word "Open".

UPDATE bugs
SET bug_status = CASE LOWER(bug_status)
    WHEN 'open' THEN 'Open'
    WHEN 'in progress' THEN 'In Progress'
    WHEN 'resolved' THEN 'Resolved'
    ELSE bug_status
END
WHERE bug_status NOT IN ('Open', 'In Progress', 'Resolved');

-- Problem found:
-- One Open bug had a resolution date and a day count filled in.

-- What this changes:
-- Clears date_resolved and resolution_days for Open bugs.

-- Why:
-- An open bug is not resolved. Leaving the date in would make the average
-- resolution time look shorter than it really is.

UPDATE bugs
SET
    date_resolved = NULL,
    resolution_days = NULL
WHERE bug_status = 'Open'
  AND (date_resolved IS NOT NULL OR resolution_days IS NOT NULL);

-- Problem found:
-- One Resolved bug had the two dates but a blank day count.

-- What this changes:
-- Calculates resolution_days from the two dates.

-- Why:
-- The average resolution time uses this column. SQLite's julianday function
-- turns a date into a day number, so subtracting the two dates gives the
-- number of days between them.

UPDATE bugs
SET resolution_days = CAST(
    julianday(date_resolved) - julianday(date_reported) AS INTEGER
)
WHERE bug_status = 'Resolved'
  AND resolution_days IS NULL
  AND date_resolved IS NOT NULL
  AND date_reported IS NOT NULL;

-- Problem found:
-- One QA test was entered twice. The copy has a different test_id but the
-- same plugin, date, setup, category, status, and duration.

-- What this changes:
-- Keeps the lower test_id and deletes the extra copy.
-- The IDs are placed in a temporary table first so the delete is easy to read.

-- Why:
-- Leaving the copy in would count one test twice and slightly inflate
-- the pass rate, because the copied row is a passing test.

DROP TABLE IF EXISTS ids_to_remove;

CREATE TEMP TABLE ids_to_remove AS
SELECT MAX(test_id) AS test_id
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

DELETE FROM qa_test_results
WHERE test_id IN (SELECT test_id FROM ids_to_remove);

DROP TABLE ids_to_remove;

-- Check that the standard values are now the only values.
-- These queries should return zero rows, or a count of zero.
-- Blank durations are still expected and are not shown here.

SELECT operating_system, COUNT(*) AS test_count
FROM qa_test_results
GROUP BY operating_system
ORDER BY operating_system;

SELECT daw, COUNT(*) AS test_count
FROM qa_test_results
GROUP BY daw
ORDER BY daw;

SELECT plugin_format, COUNT(*) AS test_count
FROM qa_test_results
GROUP BY plugin_format
ORDER BY plugin_format;

SELECT test_status, COUNT(*) AS test_count
FROM qa_test_results
GROUP BY test_status
ORDER BY test_status;

SELECT severity, COUNT(*) AS bug_count
FROM bugs
GROUP BY severity
ORDER BY severity;

SELECT bug_status, COUNT(*) AS bug_count
FROM bugs
GROUP BY bug_status
ORDER BY bug_status;

SELECT COUNT(*) AS remaining_duplicate_groups
FROM (
    SELECT plugin_id
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
    HAVING COUNT(*) > 1
) AS duplicate_groups;
