-- Audio Plugin QA Data Analysis
-- File: 01_create_tables.sql
--
-- Creates the three tables for this project.
-- Running this file deletes any data already in those tables.
-- Load the CSV files after this script. Do not run it again unless you
-- intend to reload the database from scratch.
--
-- SQLite is the database engine. The table design itself is ordinary SQL.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS bugs;
DROP TABLE IF EXISTS qa_test_results;
DROP TABLE IF EXISTS plugins;

-- One row is one plugin release.
-- Northwind Synth has two rows because QA tested version 3.0.2 and version 3.1.0.
CREATE TABLE plugins (
    plugin_id INTEGER PRIMARY KEY,
    plugin_name TEXT NOT NULL,
    plugin_category TEXT NOT NULL,
    plugin_version TEXT NOT NULL,
    release_date TEXT NOT NULL
);

-- One row is one QA test.
-- plugin_id points back to plugins.
-- test_duration_minutes is allowed to be blank.
CREATE TABLE qa_test_results (
    test_id INTEGER PRIMARY KEY,
    plugin_id INTEGER NOT NULL,
    test_date TEXT NOT NULL,
    operating_system TEXT,
    daw TEXT,
    plugin_format TEXT,
    test_category TEXT,
    test_status TEXT,
    test_duration_minutes INTEGER,
    FOREIGN KEY (plugin_id) REFERENCES plugins (plugin_id)
);

-- One row is one bug found during a test.
-- test_id points back to qa_test_results.
-- plugin_id points back to plugins.
CREATE TABLE bugs (
    bug_id INTEGER PRIMARY KEY,
    test_id INTEGER NOT NULL,
    plugin_id INTEGER NOT NULL,
    bug_category TEXT,
    severity TEXT,
    bug_status TEXT,
    date_reported TEXT,
    date_resolved TEXT,
    resolution_days INTEGER,
    FOREIGN KEY (test_id) REFERENCES qa_test_results (test_id),
    FOREIGN KEY (plugin_id) REFERENCES plugins (plugin_id)
);
