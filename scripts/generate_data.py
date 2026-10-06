"""
Create the synthetic Cedarline Audio QA dataset.

The company, plugins, tests, and bugs are fictional. They were built for a
portfolio project, not taken from a real audio company.

A few small data-quality problems are added on purpose so the SQL cleaning
steps have something realistic to fix. The random seed is fixed, so running
this script again produces the same files.

Python is only used here to create the CSV extracts. The analysis itself is
done later with SQL and Excel.
"""

import csv
import random
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
SEED = 42

PERIOD_START = date(2025, 10, 1)
PERIOD_END = date(2026, 3, 31)

# plugin_id, plugin_name, plugin_category, plugin_version, release_date
# Northwind Synth appears twice so QA can compare version 3.0.2 with 3.1.0.
PLUGINS = [
    (1, "Velvet Curve EQ", "EQ", "1.4.2", "2025-02-10"),
    (2, "Iron Gate Compressor", "Compressor", "2.1.0", "2025-04-03"),
    (3, "Harbor Plate Reverb", "Reverb", "1.8.1", "2024-11-15"),
    (4, "Lantern Delay", "Delay", "1.2.0", "2025-01-22"),
    (5, "Warm Tape Saturator", "Saturation", "1.0.5", "2025-03-18"),
    (6, "Northwind Synth", "Synthesizer", "3.0.2", "2025-06-02"),
    (7, "Northwind Synth", "Synthesizer", "3.1.0", "2025-11-18"),
    (8, "Glass Shelf EQ", "EQ", "2.0.3", "2025-08-07"),
]

# Newer release gets more test time. Older, stable plugins are tested too.
TEST_COUNTS = {
    1: 56,
    2: 54,
    3: 55,
    4: 52,
    5: 54,
    6: 50,
    7: 74,
    8: 55,
}

TEST_CATEGORIES = [
    ("Installation", 8),
    ("Plugin Scan", 8),
    ("Plugin Loading", 12),
    ("GUI", 15),
    ("Presets", 10),
    ("Automation", 10),
    ("Audio Processing", 14),
    ("CPU Performance", 8),
    ("Session Recall", 8),
    ("Compatibility", 10),
]

DURATION_RANGES = {
    "Installation": (8, 20),
    "Plugin Scan": (5, 15),
    "Plugin Loading": (5, 12),
    "GUI": (10, 25),
    "Presets": (8, 20),
    "Automation": (10, 25),
    "Audio Processing": (12, 30),
    "CPU Performance": (15, 40),
    "Session Recall": (10, 25),
    "Compatibility": (15, 35),
}

SEVERITY_WEIGHTS = {
    "Crash": [("Low", 5), ("Medium", 15), ("High", 55), ("Critical", 25)],
    "Audio Glitch": [("Low", 22), ("Medium", 43), ("High", 30), ("Critical", 5)],
    "GUI Issue": [("Low", 50), ("Medium", 38), ("High", 11), ("Critical", 1)],
    "Installation Issue": [("Low", 42), ("Medium", 40), ("High", 16), ("Critical", 2)],
    "Preset Issue": [("Low", 46), ("Medium", 40), ("High", 13), ("Critical", 1)],
    "Automation Issue": [("Low", 32), ("Medium", 46), ("High", 20), ("Critical", 2)],
    "CPU Performance": [("Low", 18), ("Medium", 42), ("High", 34), ("Critical", 6)],
    "Compatibility Issue": [("Low", 16), ("Medium", 42), ("High", 36), ("Critical", 6)],
    "Plugin Scan Failure": [("Low", 28), ("Medium", 42), ("High", 26), ("Critical", 4)],
    "Session Recall Issue": [("Low", 34), ("Medium", 44), ("High", 20), ("Critical", 2)],
}

RESOLUTION_BASE_DAYS = {
    "Low": 4,
    "Medium": 8,
    "High": 15,
    "Critical": 22,
}


def weighted_choice(rng, pairs):
    labels, weights = zip(*pairs)
    return rng.choices(list(labels), weights=list(weights), k=1)[0]


def random_date(rng, start, end):
    span = (end - start).days
    return start + timedelta(days=rng.randint(0, span))


def choose_os(rng):
    return weighted_choice(
        rng,
        [
            ("Windows 11", 32),
            ("Windows 10", 20),
            ("macOS 15", 28),
            ("macOS 14", 20),
        ],
    )


def choose_daw(rng, operating_system):
    # Logic Pro only runs on macOS. The other DAWs are tested on both.
    if operating_system.startswith("macOS"):
        return weighted_choice(
            rng,
            [
                ("Logic Pro", 36),
                ("Pro Tools", 24),
                ("Ableton Live", 24),
                ("REAPER", 16),
            ],
        )
    return weighted_choice(
        rng,
        [
            ("Pro Tools", 36),
            ("Ableton Live", 36),
            ("REAPER", 28),
        ],
    )


def choose_format(rng, daw, operating_system):
    # Keep host/format pairs realistic.
    # Logic Pro is tested as AU. Pro Tools is tested as AAX.
    # Ableton Live and REAPER are mainly VST3, with some AU tests on Mac.
    if daw == "Logic Pro":
        return "AU"
    if daw == "Pro Tools":
        return "AAX"
    if operating_system.startswith("macOS"):
        return weighted_choice(rng, [("VST3", 78), ("AU", 22)])
    return "VST3"


def fail_probability(plugin_id, operating_system, daw, plugin_format, category):
    """
    Most tests pass. A few situations fail a bit more often:
    the new Northwind Synth release, GUI checks, macOS 15, and REAPER VST3.
    """
    probability = 0.168
    if plugin_id == 7:
        probability += 0.085
    if plugin_id == 7 and category == "Compatibility":
        probability += 0.06
    if plugin_id == 7 and category == "Plugin Loading":
        probability += 0.05
    if plugin_id == 7 and daw == "Pro Tools":
        probability += 0.045
    if plugin_id == 7 and operating_system == "macOS 15":
        probability += 0.03
    if category == "GUI":
        probability += 0.028
    if operating_system == "macOS 15":
        probability += 0.018
    if daw == "REAPER" and plugin_format == "VST3":
        probability += 0.03
    if plugin_id in (1, 5, 8):
        probability -= 0.028
    if plugin_id == 4:
        probability -= 0.03
    if plugin_id == 6:
        probability -= 0.02
    return max(0.05, min(0.5, probability))


def bug_category_for(rng, test_category):
    if test_category == "Plugin Loading":
        return weighted_choice(rng, [("Crash", 55), ("Compatibility Issue", 45)])
    if test_category == "Audio Processing":
        return weighted_choice(rng, [("Audio Glitch", 90), ("Crash", 10)])
    mapping = {
        "Installation": "Installation Issue",
        "Plugin Scan": "Plugin Scan Failure",
        "GUI": "GUI Issue",
        "Presets": "Preset Issue",
        "Automation": "Automation Issue",
        "CPU Performance": "CPU Performance",
        "Session Recall": "Session Recall Issue",
        "Compatibility": "Compatibility Issue",
    }
    return mapping[test_category]


def resolution_days_for(rng, severity, bug_category):
    extra = 3 if bug_category == "Crash" else 0
    if severity == "Critical":
        extra += 2
    noise = rng.randint(-2, 5)
    return max(1, RESOLUTION_BASE_DAYS[severity] + extra + noise)


def choose_bug_status(rng, severity, reported, ideal_days, plugin_id):
    age_days = (PERIOD_END - reported).days
    proposed_end = reported + timedelta(days=ideal_days)

    if severity == "Low":
        resolve_chance = 0.92 if age_days > 21 else 0.60
    elif severity == "Medium":
        resolve_chance = 0.84 if age_days > 28 else 0.48
    elif severity == "High":
        resolve_chance = 0.66 if age_days > 40 else 0.30
    else:
        resolve_chance = 0.35 if age_days > 50 else 0.15

    # High and critical bugs on the new synth release are a bit more likely
    # to still be open at the end of the QA period.
    if plugin_id == 7 and severity in ("High", "Critical"):
        resolve_chance *= 0.72

    if proposed_end <= PERIOD_END and rng.random() < resolve_chance:
        return "Resolved", proposed_end, ideal_days
    if rng.random() < 0.42:
        return "In Progress", None, None
    return "Open", None, None


def generate_tests(rng):
    tests = []
    next_id = 1
    plugins_by_id = {row[0]: row for row in PLUGINS}

    for plugin_id, count in TEST_COUNTS.items():
        release = date.fromisoformat(plugins_by_id[plugin_id][4])
        first_day = max(PERIOD_START, release)
        for _ in range(count):
            operating_system = choose_os(rng)
            daw = choose_daw(rng, operating_system)
            plugin_format = choose_format(rng, daw, operating_system)
            category = weighted_choice(rng, TEST_CATEGORIES)
            probability = fail_probability(
                plugin_id, operating_system, daw, plugin_format, category
            )
            status = "Fail" if rng.random() < probability else "Pass"
            low, high = DURATION_RANGES[category]
            duration = rng.randint(low, high)
            if status == "Fail":
                duration += rng.randint(0, 6)
            test_date = random_date(rng, first_day, PERIOD_END)
            tests.append(
                {
                    "test_id": next_id,
                    "plugin_id": plugin_id,
                    "test_date": test_date.isoformat(),
                    "operating_system": operating_system,
                    "daw": daw,
                    "plugin_format": plugin_format,
                    "test_category": category,
                    "test_status": status,
                    "test_duration_minutes": duration,
                }
            )
            next_id += 1
    return tests


def signature(row):
    return (
        row["plugin_id"],
        row["test_date"],
        row["operating_system"],
        row["daw"],
        row["plugin_format"],
        row["test_category"],
        row["test_status"],
        row["test_duration_minutes"],
    )


def generate_bugs(rng, tests):
    failures = [row for row in tests if row["test_status"] == "Fail"]
    # Most failures become bug tickets. Some are noted and closed in the test log only.
    chosen = [row for row in failures if rng.random() < 0.90]
    bugs = []
    for index, test in enumerate(chosen, start=1):
        category = bug_category_for(rng, test["test_category"])
        severity = weighted_choice(rng, SEVERITY_WEIGHTS[category])
        # The new synth's compatibility bugs tend to be a step more serious.
        if test["plugin_id"] == 7 and category == "Compatibility Issue" and severity == "Medium":
            if rng.random() < 0.45:
                severity = "High"
        reported = date.fromisoformat(test["test_date"])
        ideal_days = resolution_days_for(rng, severity, category)
        status, resolved, days = choose_bug_status(
            rng, severity, reported, ideal_days, test["plugin_id"]
        )
        bugs.append(
            {
                "bug_id": index,
                "test_id": test["test_id"],
                "plugin_id": test["plugin_id"],
                "bug_category": category,
                "severity": severity,
                "bug_status": status,
                "date_reported": reported.isoformat(),
                "date_resolved": resolved.isoformat() if resolved else None,
                "resolution_days": days,
            }
        )
    return bugs


def apply_quality_issues(rng, tests, bugs):
    """
    Add a handful of simple problems an analyst might see in an exported file.
    The original values are still obvious, so the cleaning SQL can stay simple.
    """
    windows = [row for row in tests if row["operating_system"] == "Windows 11"]
    for row in windows[:4]:
        row["operating_system"] = "Windows11"

    reaper_rows = [row for row in tests if row["daw"] == "REAPER"]
    for row in reaper_rows[:3]:
        row["daw"] = "reaper"

    pro_tools_rows = [row for row in tests if row["daw"] == "Pro Tools"]
    for row in pro_tools_rows[:3]:
        row["daw"] = " Pro Tools "

    pass_rows = [row for row in tests if row["test_status"] == "Pass"]
    for row in pass_rows[:2]:
        row["test_status"] = "pass"

    fail_rows = [row for row in tests if row["test_status"] == "Fail"]
    fail_rows[0]["test_status"] = "FAIL"

    vst_rows = [row for row in tests if row["plugin_format"] == "VST3"]
    for row in vst_rows[:2]:
        row["plugin_format"] = "vst3"

    for row in tests[:5]:
        row["test_duration_minutes"] = None

    # Exact extra copy of one clean row. It gets a new test_id, which is how a
    # double entry often shows up. No bug points at this copied test.
    source = next(
        row
        for row in tests
        if row["test_duration_minutes"] is not None
        and row["operating_system"] == "Windows 10"
        and row["daw"] == "Ableton Live"
        and row["test_status"] == "Pass"
        and row["plugin_format"] == "VST3"
    )
    matches = [row for row in tests if signature(row) == signature(source)]
    if len(matches) != 1:
        raise RuntimeError("Expected exactly one source row to copy as the duplicate.")
    duplicate = dict(source)
    duplicate["test_id"] = max(row["test_id"] for row in tests) + 1
    tests.append(duplicate)

    medium = next(row for row in bugs if row["severity"] == "Medium")
    medium["severity"] = "medium"

    open_bugs = [row for row in bugs if row["bug_status"] == "Open"]
    open_bugs[0]["bug_status"] = "open"
    # A different open bug incorrectly has a resolution date filled in.
    open_bugs[1]["date_resolved"] = "2026-03-20"
    open_bugs[1]["resolution_days"] = 6

    resolved = next(row for row in bugs if row["bug_status"] == "Resolved")
    resolved["resolution_days"] = None


def write_csv(path, fieldnames, rows):
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            prepared = {}
            for key in fieldnames:
                value = row[key]
                prepared[key] = "" if value is None else value
            writer.writerow(prepared)


def main():
    rng = random.Random(SEED)
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    tests = generate_tests(rng)
    bugs = generate_bugs(rng, tests)
    apply_quality_issues(rng, tests, bugs)

    plugin_fields = [
        "plugin_id",
        "plugin_name",
        "plugin_category",
        "plugin_version",
        "release_date",
    ]
    test_fields = [
        "test_id",
        "plugin_id",
        "test_date",
        "operating_system",
        "daw",
        "plugin_format",
        "test_category",
        "test_status",
        "test_duration_minutes",
    ]
    bug_fields = [
        "bug_id",
        "test_id",
        "plugin_id",
        "bug_category",
        "severity",
        "bug_status",
        "date_reported",
        "date_resolved",
        "resolution_days",
    ]

    write_csv(
        DATA_DIR / "plugins.csv",
        plugin_fields,
        [
            {
                "plugin_id": row[0],
                "plugin_name": row[1],
                "plugin_category": row[2],
                "plugin_version": row[3],
                "release_date": row[4],
            }
            for row in PLUGINS
        ],
    )
    write_csv(DATA_DIR / "qa_test_results.csv", test_fields, tests)
    write_csv(DATA_DIR / "bugs.csv", bug_fields, bugs)

    print(f"Wrote {len(PLUGINS)} plugins")
    print(f"Wrote {len(tests)} QA test rows (includes 1 intentional duplicate)")
    print(f"Wrote {len(bugs)} bug rows")
    print("These files contain a few intentional data-quality issues.")
    print("Synthetic data for educational and portfolio use only.")


if __name__ == "__main__":
    main()
