# QA Analysis Summary

**To:** QA manager, Cedarline Audio
**From:** Junior data analyst
**Period:** 1 October 2025 – 31 March 2026
**Data:** Synthetic portfolio dataset. Not from a real company.

## Executive Summary

QA ran 450 tests in this period. 376 passed and 74 failed, for a pass rate of 83.6%.

The release that needs the most attention is Northwind Synth 3.1.0. It failed 17 of 74 tests (23.0%), the highest failure rate in the set, and it has the most bugs (16), including one open Critical bug.

REAPER and Logic Pro failed more often than Pro Tools or Ableton Live. The clearest compatibility slices are REAPER with VST3 (21 failures out of 92 tests, 22.8%) and Logic Pro on macOS 15 (10 failures out of 39 tests, 25.6%).

67 bugs were logged. 51 are resolved (76.1%). The average time to resolve a bug was 10.0 days. High severity bugs took longer: 16.3 days on average, compared with 4.9 days for Low severity bugs. Five High or Critical bugs are still unfinished. Two of those are Critical.

## Business Questions

This summary answers the questions QA management asked:

1. How many tests were run, and what percentage passed?
2. Which plugin releases fail most often?
3. Is the new Northwind Synth release less stable than the previous one?
4. Which DAWs, operating systems, and plugin formats fail most often?
5. Which DAW and format combination is worth a closer look?
6. What kinds of bugs show up most often?
7. How severe are the bugs, and how long do resolved bugs take?
8. How many bugs are still unfinished, and which serious ones should be first in the queue?

## Dataset Overview

The analysis uses three tables:

- `plugins`: 8 releases across EQ, compression, reverb, delay, saturation, and a synthesizer
- `qa_test_results`: 450 cleaned tests
- `bugs`: 67 bug tickets

Northwind Synth is the only product with two releases in this extract: version 3.0.2 and version 3.1.0. Version 3.1.0 shipped on 18 November 2025. Its first test in this file is 22 November 2025. Version 3.0.2 was tested across the full October–March window. Both releases have enough tests to compare (50 and 74).

Logic Pro was tested only on macOS and only as AU. Pro Tools was tested as AAX. Ableton Live and REAPER were tested mainly as VST3.

74 tests failed. 67 of those failures have a bug ticket. Seven failures do not. Bug totals are therefore a bit lower than failure totals, which is expected in this file.

## Data Quality Issues

The raw test export had 451 rows. These issues were found with `sql/02_data_quality_checks.sql` and fixed with `sql/03_data_cleaning.sql` before any rates were calculated.

| Issue | What was in the file | What the cleaning did |
| --- | --- | --- |
| Operating system spelling | 4 rows said `Windows11` | Changed to `Windows 11` |
| DAW spelling | 3 rows said `reaper` | Changed to `REAPER` |
| Extra spaces | 3 rows said ` Pro Tools ` | Trimmed the spaces |
| Test status | 2 rows said `pass`, 1 row said `FAIL` | Changed to `Pass` or `Fail` |
| Plugin format | 2 rows said `vst3` | Changed to `VST3` |
| Duplicate test | 1 extra copy of a passing test | Deleted the copy. 451 rows became 450. |
| Severity | 1 bug said `medium` | Changed to `Medium` |
| Bug status | 1 bug said `open` | Changed to `Open` |
| Open bug with a close date | 1 Open bug had a resolution date | Cleared the date and the day count |
| Resolved bug with no day count | Bug 1 was resolved but `resolution_days` was blank | Calculated 18 days from 29 November 2025 to 17 December 2025 |

Five tests have no duration. Those blanks were left blank. Filling them with an average would hide the fact that the time was not recorded. Averages of duration ignore those five rows.

## Key Findings

These numbers come from the SQL run after cleaning.

- 450 tests, 376 passes, 74 failures, 83.6% pass rate.
- Northwind Synth 3.1.0 has the highest plugin failure rate: 17 of 74 tests, 23.0%.
- Harbor Plate Reverb has the lowest: 6 of 55 tests, 10.9%.
- REAPER has the highest DAW failure rate: 22 of 102 tests, 21.6%. Pro Tools has one more failure (23) but a lower rate (15.6%) because it was tested more (147 tests).
- macOS 15 has the highest operating-system failure rate: 22 of 112 tests, 19.6%. Windows 11 has almost as many failures (20) and a lower rate (13.3%) because it has the most tests (150).
- The AU failure rate is 20.2% (18 of 89). Most of that is Logic Pro. Logic accounts for 14 of the 18 AU failures.
- GUI Issue is the most common bug category (11 bugs). Crashes are the least common (3 bugs).
- 76.1% of bugs are resolved. Average resolution time is 10.0 days.
- 6 bugs are Open and 10 are In Progress. All 6 open bugs were reported in March 2026, near the end of the period.

## Plugin Performance

Failure rate is failed tests divided by total tests.

| Plugin | Total tests | Failed tests | Failure rate | Bugs | Open bugs | High | Critical |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Northwind Synth 3.1.0 | 74 | 17 | 23.0% | 16 | 3 | 3 | 2 |
| Northwind Synth 3.0.2 | 50 | 9 | 18.0% | 8 | 0 | 4 | 0 |
| Lantern Delay 1.2.0 | 52 | 9 | 17.3% | 9 | 0 | 2 | 0 |
| Iron Gate Compressor 2.1.0 | 54 | 9 | 16.7% | 7 | 0 | 3 | 1 |
| Velvet Curve EQ 1.4.2 | 56 | 9 | 16.1% | 9 | 1 | 2 | 0 |
| Warm Tape Saturator 1.0.5 | 54 | 8 | 14.8% | 8 | 1 | 0 | 0 |
| Glass Shelf EQ 2.0.3 | 55 | 7 | 12.7% | 6 | 1 | 0 | 0 |
| Harbor Plate Reverb 1.8.1 | 55 | 6 | 10.9% | 4 | 0 | 1 | 0 |

**Observation.** Northwind Synth 3.1.0 is the weakest release in this file. The gap versus version 3.0.2 is 5 percentage points (23.0% versus 18.0%), with 17 failures versus 9. That is a real difference, and the sample is large enough to take seriously, but it is not a collapse. The other releases sit between 10.9% and 18.0%.

Version 3.1.0 also has the most bugs and the only open Critical bug in the synth line. Version 3.0.2 has 4 High bugs, and none of them are still open.

Iron Gate Compressor's failure rate is near the middle of the pack (16.7%), but it has an unresolved Critical bug. Failure rate and unfinished severity are two different signals. Both belong in the follow-up list.

**Observation on test type.** Installation tests failed more often than any other category: 10 of 35 tests, 28.6%. GUI tests failed 15 of 76, or 19.7%. Installation is the higher rate. GUI was tested more often, so that 28.6% should be treated as a lead to check, not as a final conclusion about the installer.

## Compatibility Findings

Every comparison below shows tests, failures, and the failure rate.

### DAW

| DAW | Total tests | Failed tests | Failure rate |
| --- | --- | --- | --- |
| REAPER | 102 | 22 | 21.6% |
| Logic Pro | 70 | 14 | 20.0% |
| Pro Tools | 147 | 23 | 15.6% |
| Ableton Live | 131 | 15 | 11.5% |

**Observation.** REAPER has the highest DAW failure rate. Pro Tools has the highest failure count. Those are different results because Pro Tools was tested more. Ableton Live has the lowest rate among the four hosts, at 11.5%.

### Operating system

| Operating system | Total tests | Failed tests | Failure rate |
| --- | --- | --- | --- |
| macOS 15 | 112 | 22 | 19.6% |
| Windows 10 | 96 | 18 | 18.8% |
| macOS 14 | 92 | 14 | 15.2% |
| Windows 11 | 150 | 20 | 13.3% |

**Observation.** macOS 15 is the highest rate, with Windows 10 close behind. The gap between those two is small (19.6% versus 18.8%). Windows 11 looks better on rate even though it has 20 failures, because 150 tests were run there. I would not tell the team that Windows 11 is "fine" based on the count of failures alone.

The sharper operating-system result is inside Logic Pro:

| Logic Pro on | Total tests | Failed tests | Failure rate |
| --- | --- | --- | --- |
| macOS 15 | 39 | 10 | 25.6% |
| macOS 14 | 31 | 4 | 12.9% |

Logic was not tested on Windows, which matches how that DAW is used.

### Plugin format

| Format | Total tests | Failed tests | Failure rate |
| --- | --- | --- | --- |
| AU | 89 | 18 | 20.2% |
| AAX | 147 | 23 | 15.6% |
| VST3 | 214 | 33 | 15.4% |

**Observation.** AU is higher than AAX and VST3. That does not, by itself, mean the AU format is the problem. Logic Pro is tested only as AU, and Logic accounts for 14 of the 18 AU failures. The AU rate and the Logic rate are mostly the same story.

### DAW and format

Groups with at least 5 tests:

| DAW | Format | Total tests | Failed tests | Failure rate |
| --- | --- | --- | --- | --- |
| Ableton Live | AU | 9 | 3 | 33.3% |
| REAPER | VST3 | 92 | 21 | 22.8% |
| Logic Pro | AU | 70 | 14 | 20.0% |
| Pro Tools | AAX | 147 | 23 | 15.6% |
| REAPER | AU | 10 | 1 | 10.0% |
| Ableton Live | VST3 | 122 | 12 | 9.8% |

**Observation.** Ableton Live on AU has the highest rate and the smallest sample: 3 failures out of 9 tests. I would not rank that combination as the main compatibility problem. One or two different results would move the percentage a lot.

REAPER on VST3 is the combination with both a high rate and a large sample: 21 of 92 tests, 22.8%. Logic Pro on AU is next, with 14 of 70 tests, 20.0%. Ableton Live on VST3 is the best large group, at 9.8% (12 of 122).

Every DAW and format pair in this file has at least 9 tests, so the "at least 5 tests" rule did not drop any pair. The rule is still the right check. The Ableton AU row shows why a group can pass a minimum of 5 and still be too small to treat as firm.

## Bug Findings

### Category

| Bug category | Bugs | Open | Resolved | Average days to resolve |
| --- | --- | --- | --- | --- |
| GUI Issue | 11 | 2 | 8 | 7.9 |
| Installation Issue | 10 | 0 | 8 | 9.3 |
| Compatibility Issue | 9 | 1 | 8 | 8.8 |
| Automation Issue | 8 | 1 | 6 | 10.7 |
| Audio Glitch | 6 | 0 | 6 | 8.5 |
| CPU Performance | 6 | 0 | 4 | 13.8 |
| Preset Issue | 6 | 0 | 5 | 7.4 |
| Plugin Scan Failure | 4 | 1 | 2 | 12.5 |
| Session Recall Issue | 4 | 0 | 2 | 16.0 |
| Crash | 3 | 1 | 2 | 19.5 |

**Observation.** GUI issues are the most common bug and they are not severe in this file: 6 Low and 5 Medium, with no High or Critical GUI bugs. They also close relatively quickly (7.9 days).

Crashes are uncommon. Two High crashes were resolved in 18 and 21 days. One Low crash is still open. An average of 19.5 days is based on only two resolved crashes, so I would not quote that average as a stable turnaround time.

Among categories with at least 3 resolved bugs, CPU Performance took the longest, at 13.8 days across 4 bugs. Session Recall and Crash took longer on average, but each of those averages uses only 2 resolved bugs.

### Severity and status

| Severity | Bugs | Resolved bugs | Average days |
| --- | --- | --- | --- |
| Low | 21 | 16 | 4.9 |
| Medium | 28 | 22 | 9.6 |
| High | 15 | 12 | 16.3 |
| Critical | 3 | 1 | 24.0 |

| Status | Bugs |
| --- | --- |
| Open | 6 |
| In Progress | 10 |
| Resolved | 51 |

**Observation.** Resolved High bugs took about three times as long as resolved Low bugs (16.3 days versus 4.9). That comparison has 12 High bugs and 16 Low bugs behind it, so it is more solid than the Critical average. The Critical average is one resolved bug that took 24 days. The other two Critical bugs are not resolved, so they are not in that average.

76.1% of bugs are resolved (51 of 67). The other 16 are unfinished: 6 Open and 10 In Progress.

All 6 open bugs were reported in March 2026. Some of them may simply be new. The older unfinished work is in the In Progress list. The serious ones that have been sitting since January are listed below.

### Unresolved High and Critical bugs

| Plugin | Category | Severity | Status | Reported |
| --- | --- | --- | --- | --- |
| Iron Gate Compressor 2.1.0 | CPU Performance | Critical | In Progress | 2026-01-26 |
| Northwind Synth 3.1.0 | Automation Issue | Critical | Open | 2026-03-23 |
| Iron Gate Compressor 2.1.0 | Session Recall Issue | High | In Progress | 2026-01-27 |
| Northwind Synth 3.1.0 | Session Recall Issue | High | In Progress | 2026-01-02 |
| Velvet Curve EQ 1.4.2 | Compatibility Issue | High | Open | 2026-03-24 |

## Recommendations

These are follow-ups supported by the counts above. They are not proof of the root cause.

1. **Put extra regression time on Northwind Synth 3.1.0.** It has the highest failure rate (17 of 74, 23.0%), the most bugs (16), and an open Critical automation bug reported on 23 March 2026. Compare new fixes with version 3.0.2, which failed 9 of 50 tests (18.0%) and has no open bugs.

2. **Investigate REAPER VST3 and Logic Pro on macOS 15 before treating a whole format or a whole OS as the problem.** REAPER VST3 failed 21 of 92 tests (22.8%). Logic Pro on macOS 15 failed 10 of 39 tests (25.6%), compared with 4 of 31 (12.9%) on macOS 14. The higher AU rate is mostly the Logic result, not a separate AU-wide failure.

3. **Clear the unfinished High and Critical bugs, starting with the older ones.** The Critical CPU bug on Iron Gate Compressor has been In Progress since 26 January 2026. The High session-recall bug on Northwind Synth 3.1.0 has been In Progress since 2 January 2026. The open Critical automation bug on that same release is newer, and it should still be near the front of the queue because of its severity.

4. **Review the installation failures, and do not promote the Ableton AU rate yet.** Installation failed 10 of 35 tests (28.6%). That sample is smaller than the GUI sample, so the next step is a review of those 10 failures, not a claim that installation is broken. Ableton Live on AU failed 3 of 9 tests (33.3%). Run more than 9 tests before ranking that combination with REAPER VST3.

## Limitations

- The company, plugins, tests, and bugs are synthetic. They were built so this portfolio project would have realistic QA data to practice on.
- The window is six months. A later quarter could look different, especially for version 3.1.0, which was only tested from late November onward.
- Seven failed tests have no bug ticket, so the bug table does not describe every failure.
- Five test durations are blank and were not filled in.
- Several slices are small. Ableton Live on AU has 9 tests. The crash resolution average uses 2 bugs. The Critical resolution average uses 1 bug. Those figures are reported with the sample size so they are not read as stable rates.
- The queries show where failures cluster. They do not show why. A high rate on Logic and macOS 15 is a place to investigate, not a completed root-cause analysis.
- Only Northwind Synth has two versions in this extract, so a version comparison is not available for the other products.
- "Open" is not the same thing as "ignored." All 6 open bugs were reported in March 2026.
