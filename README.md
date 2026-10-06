# Audio Plugin QA Data Analysis

## Overview

This is a portfolio project for an entry-level Data Analyst role. It analyzes QA test results and bug tickets for Cedarline Audio, a fictional company that makes audio plugins for music producers and engineers.

The work follows a simple path: take a messy export, check it, clean it with SQL, answer the QA team's questions, and summarize the results in Excel.

This project uses synthetic data created for educational and portfolio purposes. It does not contain proprietary data from any real audio software company.

SQLite is the database engine. The skill being demonstrated is SQL. Python is used only to generate the data, load it, and build the Excel workbook.

## Business Problem

The QA team tests each plugin release on several DAWs, operating systems, and plugin formats. Management wants a plain-language picture of the last six months:

- how much testing happened
- what share of tests passed
- which release is failing
- which DAWs, operating systems, and formats fail most often
- what kinds of bugs are showing up
- which serious bugs are still unfinished

A list of 450 test rows does not answer those questions. The analyst's job is to organize the data and report the rates with the counts behind them.

## Questions Answered

1. How many QA tests were run, and what was the pass rate?
2. Which plugin release has the highest failure rate?
3. Does Northwind Synth 3.1.0 fail more often than version 3.0.2?
4. Which DAW has the highest failure rate, and which DAW has the most failures?
5. Which operating system has the highest failure rate?
6. Which plugin format has the highest failure rate?
7. Which DAW and format combination is worth investigating?
8. What bug categories are most common?
9. How long do resolved bugs take, and do higher-severity bugs take longer?
10. Which High and Critical bugs are still unfinished?

## Tools Used

| Tool | Role in this project |
| --- | --- |
| SQL | Cleaning, validation, and all of the analysis |
| SQLite | The file database that runs the SQL |
| Microsoft Excel | KPI sheet, summary tables, formulas, and charts |
| Python | Generating the CSV files, loading SQLite, and creating the workbook |
| CSV | Raw extracts and the summary reports |
| Git / GitHub | Version control for the project |

Python does not analyze the data. The queries in `sql/` are the analysis. The Excel formulas recalculate the summary from the cleaned rows.

## Dataset

The data is fictional and reproducible. `scripts/generate_data.py` uses random seed 42.

The QA period is 1 October 2025 through 31 March 2026.

| Table | Rows | What one row means |
| --- | --- | --- |
| `plugins` | 8 | One plugin release |
| `qa_test_results` | 451 raw, 450 after cleaning | One QA test |
| `bugs` | 67 | One bug ticket |

There are seven product names. Northwind Synth appears twice, as version 3.0.2 and version 3.1.0, because the question "did the new release get worse?" needs both versions.

About 16% of tests fail. The host and format pairs are realistic: Logic Pro is tested as AU on macOS, Pro Tools is tested as AAX, and Ableton Live and REAPER are tested mainly as VST3.

Column definitions, keys, and examples are in [docs/data_dictionary.md](docs/data_dictionary.md).

## Database Structure

```text
plugins
  plugin_id          primary key
        |
        | one plugin release has many tests
        v
qa_test_results
  test_id            primary key
  plugin_id          foreign key → plugins.plugin_id
        |
        | a failed test may have one bug
        v
bugs
  bug_id             primary key
  test_id            foreign key → qa_test_results.test_id
  plugin_id          foreign key → plugins.plugin_id
```

`plugin_id` connects a test to a release. `test_id` connects a bug to the test that found it. In this dataset each bug belongs to one test, and a test has at most one bug. Seven failed tests have no bug ticket, so bug counts are slightly lower than failure counts.

## Data Cleaning

The files in `data/` are the raw export. They include a few problems an analyst would actually see:

- `Windows11` instead of `Windows 11` (4 rows)
- `reaper` instead of `REAPER` (3 rows)
- ` Pro Tools ` with extra spaces (3 rows)
- `pass` and `FAIL` instead of `Pass` and `Fail` (3 rows)
- `vst3` instead of `VST3` (2 rows)
- one duplicate test
- five blank test durations
- one severity stored as `medium`
- one status stored as `open`
- one open bug with a resolution date filled in by mistake
- one resolved bug with a blank day count

`sql/02_data_quality_checks.sql` finds those issues and does not change anything. `sql/03_data_cleaning.sql` fixes them with `TRIM`, `UPDATE`, and one `DELETE` for the duplicate. The duplicate was a second copy of a passing test, so leaving it in would have counted that pass twice.

The five blank durations stay blank. They are excluded from `AVG` and are not replaced with a guess.

The database file in this repository has already been cleaned. Reloading the CSVs with `scripts/load_database.py` puts the raw issues back, which is useful if you want to practice the checks.

## SQL Analysis

The queries use `SELECT`, `WHERE`, `JOIN`, `GROUP BY`, `HAVING`, `CASE`, `COUNT`, `SUM`, `AVG`, and `ROUND`. There is one common-table-expression in the plugin summary. There are no window functions.

Each major query has a short comment naming the business question and the approach.

**Failure rate by plugin.** The name lives on `plugins`, so the query joins it to the tests and groups by release. Northwind Synth 3.1.0 is 17 failures out of 74 tests.

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

**DAW and format.** `HAVING` keeps pairs with at least 5 tests. The rate is shown next to both counts so a small sample is not ranked on the percentage alone.

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

**Bugs by severity.**

```sql
SELECT severity, COUNT(*) AS bug_count
FROM bugs
GROUP BY severity;
```

**Open bugs, and average time to resolve.** The average uses resolved bugs only. Open bugs have a blank day count on purpose.

```sql
SELECT COUNT(*) AS open_bugs
FROM bugs
WHERE bug_status = 'Open';

SELECT ROUND(AVG(resolution_days), 1) AS average_resolution_days
FROM bugs
WHERE bug_status = 'Resolved';
```

The full query files are:

| File | What it answers |
| --- | --- |
| `sql/04_basic_analysis.sql` | Totals, pass rate, and counts by plugin, DAW, OS, and format |
| `sql/05_plugin_analysis.sql` | Failure rate, bugs, and the version comparison |
| `sql/06_compatibility_analysis.sql` | DAW, OS, format, and combinations |
| `sql/07_bug_analysis.sql` | Category, severity, status, and resolution time |
| `sql/08_management_summary.sql` | One KPI list for a manager |

## Excel Analysis

`excel/audio_plugin_qa_analysis.xlsx` is a simple reporting workbook.

| Sheet | What is on it |
| --- | --- |
| Management Summary | KPI list, pass rate, and charts for pass vs fail, bug status, and severity |
| Plugin Performance | Tests, failures, failure rate, bugs, and open bugs, with a bar chart |
| Compatibility | DAW, format, and DAW + format tables, with a DAW chart |
| Bug Analysis | Category, severity, and status tables, with two charts |
| QA Test Data | Cleaned tests as an Excel table with filters |
| Bug Data | Cleaned bugs used by the formulas on the other sheets |

The summary numbers are formulas, not pasted values. The workbook uses `COUNTIF`, `COUNTIFS`, `SUM`, `AVERAGE`, `AVERAGEIF`, and division for the rates. Failure rates above 20% are highlighted. Charts read from those formula cells.

A manager can sort and filter the test table without knowing SQL. The written interpretation is in [docs/analysis_summary.md](docs/analysis_summary.md).

## Key Findings

All figures are from the cleaned SQL results for October 2025 through March 2026.

- **450 tests, 83.6% pass rate.** 376 passed and 74 failed.
- **Northwind Synth 3.1.0 failed most often:** 17 of 74 tests, 23.0%. Version 3.0.2 failed 9 of 50 tests, 18.0%. Harbor Plate Reverb was the most stable release, at 6 of 55 tests, 10.9%.
- **REAPER has the highest DAW failure rate** (22 of 102, 21.6%). Pro Tools has the most failures (23) and a lower rate (15.6%) because it was tested 147 times.
- **Logic Pro on macOS 15 failed 10 of 39 tests (25.6%)**, compared with 4 of 31 (12.9%) on macOS 14. The AU format rate is higher (18 of 89, 20.2%) mostly because Logic is tested only as AU.
- **REAPER + VST3 is the combination with both a high rate and a large sample:** 21 of 92 tests, 22.8%. Ableton Live + AU is 3 of 9 tests (33.3%), which is too small to treat as the main problem.
- **67 bugs, 76.1% resolved, 10.0 days on average.** GUI issues are the most common category (11) and are Low or Medium. Resolved High bugs averaged 16.3 days, compared with 4.9 days for Low. Five High or Critical bugs are still unfinished, including a Critical CPU bug on Iron Gate Compressor that has been in progress since 26 January 2026.

## Recommendations

1. Add regression time on Northwind Synth 3.1.0 and compare it with version 3.0.2. Include the open Critical automation bug from 23 March 2026.
2. Investigate REAPER VST3 (21 of 92 tests) and Logic Pro on macOS 15 (10 of 39 tests) before calling AU, or macOS as a whole, the problem.
3. Finish the older High and Critical bugs first. The Critical CPU bug on Iron Gate Compressor has been in progress since 26 January 2026, and a High session-recall bug on Northwind Synth 3.1.0 has been in progress since 2 January 2026.
4. Review the 10 failed installation tests (10 of 35, 28.6%). Collect more than 9 Ableton AU tests before acting on that 33.3% rate.

## Repository Structure

```text
README.md
requirements.txt
.gitignore
data/
  plugins.csv
  qa_test_results.csv
  bugs.csv
database/
  audio_plugin_qa.db
sql/
  01_create_tables.sql
  02_data_quality_checks.sql
  03_data_cleaning.sql
  04_basic_analysis.sql
  05_plugin_analysis.sql
  06_compatibility_analysis.sql
  07_bug_analysis.sql
  08_management_summary.sql
excel/
  audio_plugin_qa_analysis.xlsx
reports/
  management_summary.csv
  plugin_performance.csv
  compatibility_analysis.csv
  bug_summary.csv
docs/
  data_dictionary.md
  analysis_summary.md
  interview_notes.md
  power_bi_dashboard_plan.md
scripts/
  generate_data.py
  load_database.py
  create_excel_report.py
```

## How to Run

You need Python 3 and the `sqlite3` command-line tool. The only third-party package is `openpyxl`, which builds the workbook.

The database and reports already in the repository are the cleaned results. You can open `database/audio_plugin_qa.db` in DB Browser for SQLite, or run the analysis files immediately.

To rebuild everything from scratch:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

python scripts/generate_data.py
python scripts/load_database.py

sqlite3 -header -column database/audio_plugin_qa.db < sql/02_data_quality_checks.sql
sqlite3 database/audio_plugin_qa.db < sql/03_data_cleaning.sql

sqlite3 -header -column database/audio_plugin_qa.db < sql/04_basic_analysis.sql
sqlite3 -header -column database/audio_plugin_qa.db < sql/05_plugin_analysis.sql
sqlite3 -header -column database/audio_plugin_qa.db < sql/06_compatibility_analysis.sql
sqlite3 -header -column database/audio_plugin_qa.db < sql/07_bug_analysis.sql
sqlite3 -header -column database/audio_plugin_qa.db < sql/08_management_summary.sql

python scripts/create_excel_report.py
```

`load_database.py` reloads the raw CSVs, including the data-quality issues. Run the cleaning script before the Excel script. `create_excel_report.py` stops if those issues are still present, then refreshes the CSV reports and the workbook.

Do not run `sql/01_create_tables.sql` on a database you want to keep. `load_database.py` already creates the tables. Running that file by itself deletes the loaded data.

On Windows, activate the virtual environment with `.venv\Scripts\activate`.

## Skills Demonstrated

- SQL querying
- Data cleaning
- Data validation
- Relational databases
- JOINs
- GROUP BY
- CASE statements
- Aggregations
- Basic KPIs
- Excel analysis
- Data visualization
- Business analysis
- Technical documentation
- Communicating findings

## More detail

- Written findings: [docs/analysis_summary.md](docs/analysis_summary.md)
- Column definitions: [docs/data_dictionary.md](docs/data_dictionary.md)
- How I would explain the SQL in an interview: [docs/interview_notes.md](docs/interview_notes.md)
- A beginner plan for a one-page Power BI report, without a `.pbix` file: [docs/power_bi_dashboard_plan.md](docs/power_bi_dashboard_plan.md)
