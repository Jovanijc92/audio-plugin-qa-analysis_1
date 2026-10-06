"""
Load the raw CSV files into a SQLite database.

This script creates the tables, then loads the CSV extracts as they are.
It does not clean the data. Run sql/02_data_quality_checks.sql next, then
sql/03_data_cleaning.sql.

Python is only used here to load the files. The analysis is SQL.
"""

import csv
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
DB_PATH = ROOT / "database" / "audio_plugin_qa.db"
SCHEMA_PATH = ROOT / "sql" / "01_create_tables.sql"


def blank_to_none(value):
    if value is None:
        return None
    text = str(value).strip()
    return None if text == "" else text


def parse_int(value):
    text = blank_to_none(value)
    if text is None:
        return None
    return int(text)


def read_csv(path):
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def main():
    if not SCHEMA_PATH.exists():
        raise FileNotFoundError(f"Missing schema file: {SCHEMA_PATH}")

    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    if DB_PATH.exists():
        DB_PATH.unlink()

    plugins = read_csv(DATA_DIR / "plugins.csv")
    tests = read_csv(DATA_DIR / "qa_test_results.csv")
    bugs = read_csv(DATA_DIR / "bugs.csv")

    connection = sqlite3.connect(DB_PATH)
    try:
        connection.execute("PRAGMA foreign_keys = ON")
        connection.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))

        connection.executemany(
            """
            INSERT INTO plugins (
                plugin_id, plugin_name, plugin_category, plugin_version, release_date
            ) VALUES (?, ?, ?, ?, ?)
            """,
            [
                (
                    parse_int(row["plugin_id"]),
                    row["plugin_name"],
                    row["plugin_category"],
                    row["plugin_version"],
                    row["release_date"],
                )
                for row in plugins
            ],
        )
        connection.executemany(
            """
            INSERT INTO qa_test_results (
                test_id, plugin_id, test_date, operating_system, daw,
                plugin_format, test_category, test_status, test_duration_minutes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    parse_int(row["test_id"]),
                    parse_int(row["plugin_id"]),
                    row["test_date"],
                    row["operating_system"],
                    row["daw"],
                    row["plugin_format"],
                    row["test_category"],
                    row["test_status"],
                    parse_int(row["test_duration_minutes"]),
                )
                for row in tests
            ],
        )
        connection.executemany(
            """
            INSERT INTO bugs (
                bug_id, test_id, plugin_id, bug_category, severity, bug_status,
                date_reported, date_resolved, resolution_days
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    parse_int(row["bug_id"]),
                    parse_int(row["test_id"]),
                    parse_int(row["plugin_id"]),
                    row["bug_category"],
                    row["severity"],
                    row["bug_status"],
                    row["date_reported"],
                    blank_to_none(row["date_resolved"]),
                    parse_int(row["resolution_days"]),
                )
                for row in bugs
            ],
        )
        connection.commit()
    finally:
        connection.close()

    print(f"Created {DB_PATH}")
    print(f"Loaded {len(plugins)} plugins")
    print(f"Loaded {len(tests)} QA tests (raw file, including 1 duplicate)")
    print(f"Loaded {len(bugs)} bugs")
    print("Data quality issues are still in the database.")
    print("Next: run sql/02_data_quality_checks.sql, then sql/03_data_cleaning.sql.")


if __name__ == "__main__":
    main()
