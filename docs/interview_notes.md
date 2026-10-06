# Interview Notes

These notes are for me. They explain the project in plain language so I can talk about it in an interview for a first data analyst role.

I should be honest about the scope: this is a portfolio project. I created the dataset, then analyzed it with SQL and Excel. I did not work at a real audio company, and I should not describe it as if I did.

## 30-Second Project Explanation

"This is a portfolio project where I analyzed synthetic QA data for a fictional audio plugin company. The QA team tests plugins on different DAWs, operating systems, and plugin formats, and I wanted to practice turning that kind of data into something a manager could use. There are three tables: plugins, test results, and bugs. I cleaned a few simple data issues in SQL, then calculated the pass rate, failure rates by plugin and by DAW, and how long bugs take to resolve. The main finding is that Northwind Synth 3.1.0 failed more often than the other releases, and REAPER and Logic Pro had higher failure rates than Pro Tools or Ableton. I summarized the KPIs in Excel. The data is fictional and I built it for this project."

## Business Problem

Cedarline Audio is a made-up company that sells audio plugins. The QA team runs the same kinds of checks a real plugin team would run: does it install, does the DAW scan it, does the interface work, does it pass audio, and does it survive on different computers.

A manager does not want a list of 450 test rows. They want a short set of numbers: how much testing happened, what share passed, which release is failing, which DAW or operating system looks worse, and which serious bugs are still open.

My job in the project was to clean the export, answer those questions in SQL, and put the answers in an Excel workbook a non-technical person can read.

## Database Structure

I used three tables because the data is three different things.

- `plugins` is the product list. One row is one release. Northwind Synth has two rows, one for version 3.0.2 and one for version 3.1.0.
- `qa_test_results` is the test log. One row is one test. It points at a plugin with `plugin_id`.
- `bugs` is the ticket list. One row is one bug. It points at the test that found it and at the plugin.

If I had put everything in one flat sheet, the plugin name and version would be repeated on every test row, and bug details would be squeezed onto test rows that do not have a bug. Separate tables keep each fact in one place. The `JOIN` puts them back together when a question needs more than one table.

A primary key identifies a row. `test_id` 139 is one specific test.

A foreign key points at a primary key in another table. `plugin_id` on a test has to match a real plugin. That is what makes the relationship real, not just two spreadsheets that happen to share a column name.

In this file, one plugin has many tests. One test has at most one bug. Some failed tests have no bug at all: 74 failures, 67 bugs, so 7 failures were never ticketed.

## SQL Skills Used

**SELECT / FROM.** `SELECT` chooses the columns. `FROM` chooses the table. Every query starts there.

**WHERE.** Keeps rows that match a condition, before any grouping. `WHERE test_status = 'Fail'` keeps only failures. `WHERE bug_status = 'Resolved'` keeps only closed bugs so the average resolution time is not pulled down by blank day counts.

**GROUP BY.** Collapses rows that share a value. `GROUP BY daw` turns 450 tests into one row per DAW. Anything in the `SELECT` that is not inside `COUNT` or `SUM` needs to be in the `GROUP BY`. I grouped by `plugin_id` as well as the name, because two rows are both called Northwind Synth.

**JOIN.** Stitches tables together on a key. `INNER JOIN` keeps matches on both sides. I used it to attach plugin names to tests. `LEFT JOIN` keeps the left table even when the right table has no match. I used it so a plugin with no bugs would still appear, with a bug count of zero. In this particular file every plugin has at least one bug, but the left join is still the right pattern.

**CASE.** Replaces an if-statement inside a query. `SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END)` counts failures inside a group. I also used `CASE` to turn `pass` and `FAIL` into `Pass` and `Fail` during cleaning.

**HAVING.** Filters groups after `GROUP BY`. `WHERE` cannot do that, because the group does not exist yet. I used `HAVING COUNT(*) >= 5` so a DAW and format pair with only a couple of tests would not be ranked as if the rate were solid.

**COUNT.** Counts rows. `COUNT(*)` counts every test, including the five with a blank duration. `COUNT(test_duration_minutes)` would skip those five, so it would undercount the tests.

**AVG.** Averages a number and skips blanks. `AVG(resolution_days)` on resolved bugs is the average time to close. Blank day counts on open bugs are ignored, and I still filtered to `Resolved` so the intent is obvious.

**Percentages.** I multiply by `100.0` before dividing. In SQLite, dividing two integers drops the decimal. `74 / 450` would become 0. `100.0 * 74 / 450` becomes 16.4. I then `ROUND` to one decimal place. I always show the count next to the rate.

## Five SQL Queries I Should Understand

### 1. Overall pass rate

**Question.** What share of tests passed?

```sql
SELECT
    COUNT(*) AS total_tests,
    SUM(CASE WHEN test_status = 'Pass' THEN 1 ELSE 0 END) AS passed_tests,
    SUM(CASE WHEN test_status = 'Fail' THEN 1 ELSE 0 END) AS failed_tests,
    ROUND(
        100.0 * SUM(CASE WHEN test_status = 'Pass' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS pass_rate_pct
FROM qa_test_results;
```

**How it works.** `COUNT(*)` is every test. The two `SUM(CASE ...)` expressions count passes and failures in the same pass over the table. The rate is passed tests divided by all tests, multiplied by 100.

**JOIN.** None. The question only needs the test table.

**GROUP BY.** None. I want one row for the whole period, not one row per plugin.

**Percentage.** `100.0 * passed / total`, rounded to one decimal. Result: 450 tests, 376 passes, 74 failures, 83.6%.

**What it means.** About 5 in 6 tests passed. The failure rate is the other side of the same number, 16.4%.

### 2. Failure rate by plugin

**Question.** Which release fails most often?

```sql
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
ORDER BY failure_rate_pct DESC;
```

**How it works.** The join adds the plugin name and version onto each test. `GROUP BY` makes one row per release. `COUNT(*)` is the tests for that release. The `CASE` counts only failures. The rate is failures divided by tests.

**Why the JOIN is needed.** The test table only has `plugin_id`. The name and version live on `plugins`. Without the join I would be reporting ID numbers.

**What GROUP BY does.** It rolls the tests up to one line per release. Grouping by `plugin_id` keeps Northwind Synth 3.0.2 separate from 3.1.0. Grouping by name alone would mix those two releases together.

**Percentage.** Same pattern as the pass rate: `100.0 * failed / total`.

**What it means.** Northwind Synth 3.1.0 is first, at 17 of 74 tests, 23.0%. Harbor Plate Reverb is last, at 6 of 55, 10.9%. I keep the test count visible so a small sample is not treated like a large one.

### 3. DAW and plugin format

**Question.** Which host and format combination fails most often, once tiny groups are set aside?

```sql
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
ORDER BY failure_rate_pct DESC;
```

**How it works.** `GROUP BY daw, plugin_format` builds one row per pair, such as REAPER plus VST3. The counts and the rate use the same pattern as the plugin query. `HAVING COUNT(*) >= 5` drops pairs that were barely tested. `ORDER BY` puts the highest rate first.

**JOIN.** None. DAW and format are both on the test table.

**What GROUP BY does.** It defines the pair. A test only lands in one pair.

**Percentage.** Failures in that pair divided by tests in that pair.

**What it means.** Ableton Live on AU is 33.3%, but that is 3 failures out of 9 tests. I do not lead with that number. REAPER on VST3 is 21 of 92 tests, 22.8%, which is a much stronger signal. This query is also how I explain that a high rate on a small denominator can be misleading.

### 4. Average resolution time by severity

**Question.** Do more serious bugs take longer to close?

```sql
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
END;
```

**How it works.** `WHERE` keeps closed bugs only. `GROUP BY severity` makes one row per level. `AVG` averages `resolution_days`. `COUNT(*)` shows how many bugs are behind each average. The `CASE` in `ORDER BY` sorts Low through Critical instead of alphabetically. Alphabetically, Critical would come first and the scale would look scrambled.

**JOIN.** None. Severity and status are on the bug table.

**What GROUP BY does.** One row per severity instead of one row per bug.

**Percentage.** This query does not use a percentage. The related resolved-share query is `100.0 * resolved bugs / all bugs`, which is 51 / 67 = 76.1%.

**What it means.** Low bugs that were resolved averaged 4.9 days (16 bugs). Medium averaged 9.6 days (22 bugs). High averaged 16.3 days (12 bugs). Critical averaged 24 days, and that average is one bug. I say the High versus Low comparison out loud. I mention the Critical number only with the sample size.

### 5. Unresolved High and Critical bugs

**Question.** Which serious bugs are still unfinished, and which plugin do they belong to?

```sql
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
```

**How it works.** The join adds the plugin name. `WHERE` keeps two lists at once: unfinished statuses, and the two serious severities. `IN` is just a shorter way to write several `OR` conditions. The `CASE` in `ORDER BY` puts Critical before High. Plugin name and report date break the ties. This is the same query as in `sql/07_bug_analysis.sql`.

**Why the JOIN is needed.** The bug table has `plugin_id`. The manager needs the product name and version.

**GROUP BY.** None. This is a detail list, not a summary. Each row is one bug a person can go open.

**Percentage.** None. A list of five bugs does not need a rate.

**What it means.** There are five unfinished High or Critical bugs. The two Critical ones are a CPU bug on Iron Gate Compressor, in progress since 26 January 2026, and an automation bug on Northwind Synth 3.1.0, opened on 23 March 2026. This is the short list I would actually hand to QA.

## Possible Interview Questions

### 1. Tell me about this project.

I built a small QA analysis for a fictional audio plugin company so I could practice the work an entry-level analyst does: clean an export, answer business questions in SQL, and summarize the results in Excel. The data is synthetic. The main result is that Northwind Synth 3.1.0 had the highest failure rate, 17 failures out of 74 tests, and REAPER and Logic Pro failed more often than the other DAWs.

### 2. Why not keep this in one Excel sheet from the start?

I could have, and the workbook does contain the cleaned rows. I used tables because the same plugin is tested many times, and only some tests produce a bug. A relational structure keeps the product listed once and lets me join it when I need the name. Excel is where I present the result. SQL is where I calculate it.

### 3. What is the difference between a primary key and a foreign key here?

`plugin_id` on the plugins table is a primary key. It identifies one release and does not repeat. `plugin_id` on the test table is a foreign key. It points back at that release. If a test had a `plugin_id` that does not exist, the join would not find a name, and I would know the export was broken. I checked for that. There were no orphan tests or bugs.

### 4. How do you calculate a failure rate, and why do you show the number of tests?

Failed tests divided by total tests. I multiply by 100 to show a percent, and I round to one decimal. I always show the numerator and the denominator because 3 failures out of 9 tests is not the same kind of evidence as 21 failures out of 92. Ableton Live on AU is the example I use: 33.3% sounds alarming, and the sample is only 9 tests.

### 5. What is the difference between WHERE and HAVING?

`WHERE` filters rows before they are grouped. `HAVING` filters the groups. I use `WHERE bug_status = 'Resolved'` to throw out open bugs before I average the resolution time. I use `HAVING COUNT(*) >= 5` after grouping DAW and format, because I do not know the group size until the `GROUP BY` has happened.

### 6. When did you use an INNER JOIN, and when a LEFT JOIN?

I use an inner join when I only want rows that match, such as tests that have a plugin name. I use a left join when I start from plugins and still want a plugin that might have zero bugs. `COUNT(bug_id)` on a left join counts bugs and ignores the empty match. `COUNT(*)` would count the plugin row itself and would show 1 bug when there were none.

### 7. What data problems did you find?

The raw export had mixed labels: `Windows11`, `reaper`, ` Pro Tools ` with spaces, `pass`, `FAIL`, and `vst3`. One test was entered twice. One bug severity was `medium`, one status was `open`, one open bug had a close date filled in, and one resolved bug was missing its day count. I fixed those with `TRIM`, a few `UPDATE` statements, and a `DELETE` for the duplicate. I left five blank durations blank, because I did not want to invent a number.

### 8. Pro Tools had the most failed tests. Is it the worst DAW?

No. Pro Tools had 23 failures and REAPER had 22, but Pro Tools was tested 147 times and REAPER was tested 102 times. Pro Tools failed 15.6% of the time. REAPER failed 21.6% of the time. The count answers "where did the most failures happen?" The rate answers "where did tests fail most often?" I report both.

### 9. What would you tell the QA manager?

I would say three things. First, schedule more regression on Northwind Synth 3.1.0 and compare it with 3.0.2. Second, look at REAPER VST3 and at Logic Pro on macOS 15, because those slices have enough tests to be worth the time. Third, the Critical CPU bug on Iron Gate has been in progress since late January, so that belongs at the front of the unfinished queue along with the newer Critical automation bug on Northwind.

### 10. What are the limits of this analysis, and what would you do next?

The data is synthetic and covers six months, so I would not treat the rates as a property of real products. The queries show where failures cluster. They do not show the cause. Seven failed tests never became bugs, so the bug table is not a complete failure list. If I continued, I would ask QA for the notes on the 10 failed installation tests and on the 21 failed REAPER VST3 tests, and I would want another month of results after any fix to version 3.1.0. I would not build a model for this. The useful next step is a closer look at those specific failures.

## Things I should not say

- I should not say I was the analyst at a real plugin company.
- I should not say the data proves the cause. It shows the pattern.
- I should not quote the Ableton AU rate, the crash average, or the Critical average without the sample size.
- I should not describe the SQL as advanced. It is `SELECT`, `JOIN`, `GROUP BY`, `CASE`, and `HAVING`. That is the point.
