-- ============================================================
-- Bosch Rexroth AG | Predictive Maintenance
-- Script 02: Data Exploration & Validation
-- Database: bosch_maintenance
-- Author: David Osoba | Amdari Work Experience Programme
-- ============================================================

-- Run this script after importing the CSV files to validate
-- that all records loaded correctly and data quality is sound.


-- ─────────────────────────────────────────
-- SECTION 1: RECORD COUNT VALIDATION
-- ─────────────────────────────────────────

-- Confirm row counts match expected values:
-- equipment_master: 10 | failure_labels: 9
-- maintenance_log: 51  | sensor_telemetry: 864,000

SELECT 'equipment_master' AS table_name, COUNT(*) AS row_count FROM equipment_master
UNION ALL
SELECT 'failure_labels',  COUNT(*) FROM failure_labels
UNION ALL
SELECT 'maintenance_log', COUNT(*) FROM maintenance_log
UNION ALL
SELECT 'sensor_telemetry', COUNT(*) FROM sensor_telemetry;


-- ─────────────────────────────────────────
-- SECTION 2: PREVIEW EACH TABLE
-- ─────────────────────────────────────────

SELECT * FROM equipment_master LIMIT 5;

SELECT * FROM failure_labels LIMIT 5;

SELECT * FROM maintenance_log LIMIT 5;

SELECT * FROM sensor_telemetry LIMIT 5;


-- ─────────────────────────────────────────
-- SECTION 3: SENSOR TELEMETRY OVERVIEW
-- ─────────────────────────────────────────

-- Date range and machine count
SELECT
    MIN(timestamp)              AS earliest_reading,
    MAX(timestamp)              AS latest_reading,
    COUNT(DISTINCT machine_id)  AS total_machines
FROM sensor_telemetry;

-- Failure mode distribution (non-null rows only)
SELECT
    failure_mode,
    COUNT(*) AS occurrences
FROM sensor_telemetry
WHERE failure_mode IS NOT NULL
GROUP BY failure_mode
ORDER BY occurrences DESC;

-- Maintenance activity by action type
SELECT
    action_type,
    COUNT(*)                    AS total_actions,
    ROUND(AVG(cost_usd), 2)    AS avg_cost
FROM maintenance_log
GROUP BY action_type
ORDER BY total_actions DESC;


-- ─────────────────────────────────────────
-- SECTION 4: MISSING VALUE CHECKS
-- ─────────────────────────────────────────

-- Sensor telemetry missing values
SELECT
    COUNT(*)                                        AS total_rows,
    COUNT(*) FILTER (WHERE pressure_bar IS NULL)    AS missing_pressure,
    COUNT(*) FILTER (WHERE temp_celsius IS NULL)    AS missing_temp,
    COUNT(*) FILTER (WHERE flow_lpm IS NULL)        AS missing_flow,
    COUNT(*) FILTER (WHERE vibration_x_g IS NULL)   AS missing_vibration_x,
    COUNT(*) FILTER (WHERE vibration_y_g IS NULL)   AS missing_vibration_y,
    COUNT(*) FILTER (WHERE pump_rpm IS NULL)        AS missing_rpm
FROM sensor_telemetry;

-- Sensor dropout flag distribution
SELECT
    is_sensor_dropout,
    COUNT(*) AS row_count
FROM sensor_telemetry
GROUP BY is_sensor_dropout;

-- Missing values in failure_labels
SELECT
    COUNT(*)                                                    AS total_rows,
    COUNT(*) FILTER (WHERE machine_id IS NULL)                  AS missing_machine_id,
    COUNT(*) FILTER (WHERE failure_timestamp IS NULL)           AS missing_timestamp,
    COUNT(*) FILTER (WHERE failure_mode IS NULL)                AS missing_failure_mode,
    COUNT(*) FILTER (WHERE repair_cost_usd IS NULL)             AS missing_cost,
    COUNT(*) FILTER (WHERE downtime_hours IS NULL)              AS missing_downtime
FROM failure_labels;

-- Missing values in maintenance_log
SELECT
    COUNT(*)                                                    AS total_rows,
    COUNT(*) FILTER (WHERE machine_id IS NULL)                  AS missing_machine_id,
    COUNT(*) FILTER (WHERE action_timestamp IS NULL)            AS missing_timestamp,
    COUNT(*) FILTER (WHERE action_type IS NULL)                 AS missing_action_type,
    COUNT(*) FILTER (WHERE component_replaced IS NULL)          AS missing_component,
    COUNT(*) FILTER (WHERE cost_usd IS NULL)                    AS missing_cost
FROM maintenance_log;

-- Missing values in equipment_master
SELECT
    COUNT(*)                                                        AS total_rows,
    COUNT(*) FILTER (WHERE installation_date IS NULL)               AS missing_install_date,
    COUNT(*) FILTER (WHERE total_operating_hours IS NULL)           AS missing_hours,
    COUNT(*) FILTER (WHERE fluid_type IS NULL)                      AS missing_fluid,
    COUNT(*) FILTER (WHERE last_filter_change_date IS NULL)         AS missing_filter_date,
    COUNT(*) FILTER (WHERE maintenance_priority IS NULL)            AS missing_priority
FROM equipment_master;


-- ─────────────────────────────────────────
-- SECTION 5: REFERENTIAL INTEGRITY CHECK
-- ─────────────────────────────────────────

-- Check for machine IDs in sensor_telemetry not in equipment_master
-- Empty result = clean referential integrity
SELECT DISTINCT st.machine_id
FROM sensor_telemetry st
LEFT JOIN equipment_master em ON st.machine_id = em.machine_id
WHERE em.machine_id IS NULL;


-- ─────────────────────────────────────────
-- SECTION 6: DUPLICATE CHECKS
-- ─────────────────────────────────────────

-- Duplicates in failure_labels
SELECT machine_id, failure_timestamp, COUNT(*) AS duplicates
FROM failure_labels
GROUP BY machine_id, failure_timestamp
HAVING COUNT(*) > 1;

-- Duplicates in maintenance_log
SELECT maintenance_id, COUNT(*) AS duplicates
FROM maintenance_log
GROUP BY maintenance_id
HAVING COUNT(*) > 1;

-- Duplicates in equipment_master
SELECT machine_id, COUNT(*) AS duplicates
FROM equipment_master
GROUP BY machine_id
HAVING COUNT(*) > 1;


-- ─────────────────────────────────────────
-- SECTION 7: SENSOR DROPOUT DISTRIBUTION
-- ─────────────────────────────────────────

-- Dropout count per machine
SELECT
    machine_id,
    SUM(is_sensor_dropout) AS total_dropouts
FROM sensor_telemetry
GROUP BY machine_id
ORDER BY total_dropouts DESC;
