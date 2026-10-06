# Power BI Dashboard Plan

This project does not include a Power BI file. This note explains how the cleaned files could be imported into Power BI Desktop for a simple one-page dashboard.

Power BI is a reasonable next step after SQL and Excel. The page below uses the same numbers the SQL already calculated. It does not require advanced DAX.

## What to import

In Power BI Desktop, use **Get data → Text/CSV** and import:

| File | Use it for |
| --- | --- |
| `reports/management_summary.csv` | The headline KPI list |
| `reports/plugin_performance.csv` | Failure rate by plugin |
| `reports/bug_summary.csv` | Bug count by category |
| `excel/audio_plugin_qa_analysis.xlsx` | The **QA Test Data** sheet, for a DAW chart counted from the tests |
| `excel/audio_plugin_qa_analysis.xlsx` | The **Bug Data** sheet, for a severity chart |

The Excel workbook is optional if you would rather export those two sheets to CSV first. Either way, import the cleaned data, not the raw CSV files in `data/`. The raw files still contain the spelling issues that `sql/03_data_cleaning.sql` fixes.

After import, check the types in Power Query:

- Counts and rates should be decimal numbers.
- `failure_rate_pct` is already a percent number such as 23.0, meaning 23 percent. Format that column as a decimal number, or divide by 100 if you want Power BI's percent format.
- Dates on the Excel sheets can stay as dates.

Close and apply. You do not need to build a relationship for this one-page draft, because each chart can come from one table.

## Page layout

One page is enough. Suggested name: **QA Overview**.

Put four cards across the top and four charts underneath.

### KPI cards

| Card | Table | Field | What it shows |
| --- | --- | --- | --- |
| Total Tests | management_summary | The `value` on the row where `metric` is `Total QA Tests` | 450 tests |
| Pass Rate | management_summary | The `value` on the row where `metric` is `Overall Pass Rate (%)` | 83.6 percent |
| Total Bugs | management_summary | The `value` on the row where `metric` is `Total Bugs` | 67 bugs |
| Open Bugs | management_summary | The `value` on the row where `metric` is `Open Bugs` | 6 open bugs |

An easy way to build a card without DAX: filter the visual to the one metric row, then put `value` on the card. If you later learn measures, a measure such as a count of test rows can replace the imported total. That is optional here.

### Charts

**1. Failure rate by plugin**

- Visual: bar chart
- Table: `plugin_performance`
- Axis: `plugin_name`
- Values: `failure_rate_pct`
- Sort: failure rate, descending
- Tooltip: also show `total_tests` and `failed_tests`

The tooltip matters. Northwind Synth 3.1.0 is at 23.0 percent with 74 tests. A viewer should see the test count, not only the rate.

**2. Failed tests by DAW**

- Visual: bar chart
- Table: QA Test Data
- Axis: `DAW`
- Values: count of rows
- Filter on this visual: `Test Status` = Fail

This chart shows the failure **count**. Pro Tools has the most failed tests because it has the most tests. Pair it with the failure-rate table in Excel or with a second visual that shows the rate, so the count is not read on its own.

To show the rate instead, count failed tests divided by count of tests. If you have not written DAX yet, skip the measure and use the DAW table already on the Compatibility sheet in Excel.

**3. Bug count by category**

- Visual: bar chart
- Table: `bug_summary`
- Axis: `bug_category`
- Values: `bug_count`
- Sort: bug count, descending

GUI Issue is the largest category, with 11 bugs.

**4. Bug count by severity**

- Visual: column chart
- Table: Bug Data
- Axis: `Severity`
- Values: count of `Bug ID`
- Sort the axis manually as Low, Medium, High, Critical so the scale reads in order

High has 15 bugs and Critical has 3.

## What this page is for

The page answers four manager questions:

1. How much testing happened, and what share passed?
2. Which plugin release has the highest failure rate?
3. Which DAW produced the most failed tests?
4. What kinds of bugs are in the backlog, and how serious are they?

Keep the page to those questions. A first dashboard gets harder to explain when it has too many visuals.

## What this plan does not claim

No `.pbix` file was built for this project. The SQL queries and the Excel workbook are the analysis. This note only shows that the same cleaned tables could be loaded into a BI tool later.
