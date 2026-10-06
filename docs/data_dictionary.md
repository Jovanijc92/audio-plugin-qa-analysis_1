# Data Dictionary

This document describes the three tables in the Cedarline Audio QA database. Cedarline Audio is fictional. The rows were created for this portfolio project.

The database file is `database/audio_plugin_qa.db`. SQLite is the engine used to run the SQL. Dates are stored as text in `YYYY-MM-DD` form, which sorts correctly in SQL.

## How the tables connect

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
        | one test has at most one bug in this dataset
        v
bugs
  bug_id             primary key
  test_id            foreign key → qa_test_results.test_id
  plugin_id          foreign key → plugins.plugin_id
```

A **primary key** is the value that identifies one row and cannot repeat. `plugin_id` 7 always means Northwind Synth version 3.1.0.

A **foreign key** is a value that points at a primary key in another table. `qa_test_results.plugin_id` has to match a real `plugins.plugin_id`. That is how a test is tied to a plugin.

Not every failed test has a bug. In the cleaned data, 74 tests failed and 67 bugs were logged. Seven failures never became a ticket. A passing test does not have a bug.

Northwind Synth has two rows in `plugins` because QA tested version 3.0.2 and version 3.1.0. Those rows share a name and have different `plugin_id` values. Queries that compare plugins need to group by `plugin_id`, not by name alone.

## plugins

One row is one plugin release. There are 8 rows.

| Column | Data type | Description | Example |
| --- | --- | --- | --- |
| plugin_id | INTEGER | Primary key. Identifies one release. | 7 |
| plugin_name | TEXT | Fictional product name. | Northwind Synth |
| plugin_category | TEXT | Product family, such as EQ or Reverb. | Synthesizer |
| plugin_version | TEXT | Release number. Stored as text so values like 1.4.2 stay intact. | 3.1.0 |
| release_date | TEXT | Date the release shipped, in YYYY-MM-DD form. | 2025-11-18 |

Example row:

| plugin_id | plugin_name | plugin_category | plugin_version | release_date |
| --- | --- | --- | --- | --- |
| 7 | Northwind Synth | Synthesizer | 3.1.0 | 2025-11-18 |

The eight releases are Velvet Curve EQ 1.4.2, Iron Gate Compressor 2.1.0, Harbor Plate Reverb 1.8.1, Lantern Delay 1.2.0, Warm Tape Saturator 1.0.5, Northwind Synth 3.0.2, Northwind Synth 3.1.0, and Glass Shelf EQ 2.0.3.

## qa_test_results

One row is one QA test. The raw CSV has 451 rows, including one duplicate. The cleaned table has 450 rows.

The QA window is 1 October 2025 through 31 March 2026. Northwind Synth 3.1.0 was released on 18 November 2025, so its tests start on 22 November 2025 rather than on 1 October.

| Column | Data type | Description | Example |
| --- | --- | --- | --- |
| test_id | INTEGER | Primary key. Identifies one test. | 139 |
| plugin_id | INTEGER | Foreign key to `plugins.plugin_id`. | 3 |
| test_date | TEXT | Date the test was run, in YYYY-MM-DD form. | 2025-10-01 |
| operating_system | TEXT | Windows 11, Windows 10, macOS 15, or macOS 14. | Windows 11 |
| daw | TEXT | Host application: Pro Tools, Logic Pro, Ableton Live, or REAPER. | REAPER |
| plugin_format | TEXT | VST3, AU, or AAX. | VST3 |
| test_category | TEXT | What the test checked, such as GUI or Installation. | GUI |
| test_status | TEXT | Pass or Fail. | Pass |
| test_duration_minutes | INTEGER | How long the test took. Blank on 5 tests. | 18 |

Example row, after cleaning:

| test_id | plugin_id | test_date | operating_system | daw | plugin_format | test_category | test_status | test_duration_minutes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 139 | 3 | 2025-10-01 | Windows 11 | REAPER | VST3 | GUI | Pass | 18 |

The host and format combinations are realistic:

- Logic Pro is tested on macOS only, and only as AU.
- Pro Tools is tested as AAX.
- Ableton Live and REAPER are tested mainly as VST3. On macOS they also have a smaller number of AU tests.

## bugs

One row is one bug ticket. There are 67 rows. Each bug points at exactly one test, and no test has more than one bug.

| Column | Data type | Description | Example |
| --- | --- | --- | --- |
| bug_id | INTEGER | Primary key. Identifies one bug. | 2 |
| test_id | INTEGER | Foreign key to `qa_test_results.test_id`. The test that found the bug. | 23 |
| plugin_id | INTEGER | Foreign key to `plugins.plugin_id`. Matches the plugin on that test. | 1 |
| bug_category | TEXT | Kind of bug, such as GUI Issue or Crash. | Preset Issue |
| severity | TEXT | Low, Medium, High, or Critical. | Low |
| bug_status | TEXT | Open, In Progress, or Resolved. | Resolved |
| date_reported | TEXT | Date the bug was opened, in YYYY-MM-DD form. | 2025-12-18 |
| date_resolved | TEXT | Date the bug was closed. Blank when the bug is not resolved. | 2025-12-25 |
| resolution_days | INTEGER | Days from `date_reported` to `date_resolved`. Blank when the bug is not resolved. | 7 |

Example row:

| bug_id | test_id | plugin_id | bug_category | severity | bug_status | date_reported | date_resolved | resolution_days |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2 | 23 | 1 | Preset Issue | Low | Resolved | 2025-12-18 | 2025-12-25 | 7 |

`resolution_days` is the number of days between the two dates. For bug 2, 18 December to 25 December is 7 days. Open and In Progress bugs do not have a resolution date or a day count. That is expected. Those blanks are not data errors.

## Values used in the cleaned data

**plugin_category:** EQ, Compressor, Reverb, Delay, Saturation, Synthesizer

**operating_system:** Windows 11, Windows 10, macOS 15, macOS 14

**daw:** Pro Tools, Logic Pro, Ableton Live, REAPER

**plugin_format:** VST3, AU, AAX

**test_category:** Installation, Plugin Scan, Plugin Loading, GUI, Presets, Automation, Audio Processing, CPU Performance, Session Recall, Compatibility

**test_status:** Pass, Fail

**bug_category:** Crash, Audio Glitch, GUI Issue, Installation Issue, Preset Issue, Automation Issue, CPU Performance, Compatibility Issue, Plugin Scan Failure, Session Recall Issue

**severity:** Low, Medium, High, Critical

**bug_status:** Open, In Progress, Resolved
