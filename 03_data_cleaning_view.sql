-- ============================================================
-- Bosch Rexroth AG | Predictive Maintenance
-- Script 03: Data Cleaning View
-- Database: bosch_maintenance
-- Author: David Osoba | Amdari Work Experience Programme
-- ============================================================

-- This script creates the sensor_telemetry_cleaned view.
-- It resolves 2,590 sensor dropout events (is_sensor_dropout = 1)
-- using forward-fill interpolation via PostgreSQL window functions.

-- APPROACH: Forward-fill
-- Rather than deleting dropout rows or filling with column averages,
-- we carry the last known valid sensor reading forward until the next
-- valid reading appears. This preserves time-series continuity.

-- HOW IT WORKS:
-- Step 1: COUNT(column) OVER (PARTITION BY machine_id ORDER BY timestamp)
--         counts only non-null values as it moves forward in time.
--         During NULL sequences the count stays the same, grouping
--         NULL rows with the last valid reading before them.
-- Step 2: MAX(column) OVER (PARTITION BY machine_id, group)
--         picks the non-null value within each group and applies
--         it to all rows in that group, including the NULL rows.

-- NOTE: is_sensor_dropout is passed through unchanged.
--       Dropout rows still carry is_sensor_dropout = 1 after cleaning,
--       allowing downstream filtering if needed.

-- If the view already exists, drop it first before recreating.
-- DROP VIEW sensor_telemetry_cleaned;

CREATE VIEW sensor_telemetry_cleaned AS
WITH grouped AS (
    SELECT *,
        COUNT(pressure_bar)     OVER (PARTITION BY machine_id ORDER BY timestamp) AS pressure_grp,
        COUNT(temp_celsius)     OVER (PARTITION BY machine_id ORDER BY timestamp) AS temp_grp,
        COUNT(flow_lpm)         OVER (PARTITION BY machine_id ORDER BY timestamp) AS flow_grp,
        COUNT(vibration_x_g)    OVER (PARTITION BY machine_id ORDER BY timestamp) AS vib_x_grp,
        COUNT(vibration_y_g)    OVER (PARTITION BY machine_id ORDER BY timestamp) AS vib_y_grp,
        COUNT(pump_rpm)         OVER (PARTITION BY machine_id ORDER BY timestamp) AS rpm_grp
    FROM sensor_telemetry
)
SELECT
    telemetry_id,
    timestamp,
    machine_id,
    is_sensor_dropout,
    failure_mode,
    rul_hours,
    is_anomaly,
    shift,
    day_of_week,
    MAX(pressure_bar)   OVER (PARTITION BY machine_id, pressure_grp)   AS pressure_bar,
    MAX(temp_celsius)   OVER (PARTITION BY machine_id, temp_grp)        AS temp_celsius,
    MAX(flow_lpm)       OVER (PARTITION BY machine_id, flow_grp)        AS flow_lpm,
    MAX(vibration_x_g)  OVER (PARTITION BY machine_id, vib_x_grp)      AS vibration_x_g,
    MAX(vibration_y_g)  OVER (PARTITION BY machine_id, vib_y_grp)      AS vibration_y_g,
    MAX(pump_rpm)       OVER (PARTITION BY machine_id, rpm_grp)         AS pump_rpm
FROM grouped;


-- ─────────────────────────────────────────
-- VALIDATION: Confirm no missing values remain
-- ─────────────────────────────────────────

SELECT
    COUNT(*)                                        AS total_rows,
    COUNT(*) FILTER (WHERE pressure_bar IS NULL)    AS missing_pressure,
    COUNT(*) FILTER (WHERE temp_celsius IS NULL)    AS missing_temp,
    COUNT(*) FILTER (WHERE flow_lpm IS NULL)        AS missing_flow,
    COUNT(*) FILTER (WHERE vibration_x_g IS NULL)   AS missing_vibration_x,
    COUNT(*) FILTER (WHERE vibration_y_g IS NULL)   AS missing_vibration_y,
    COUNT(*) FILTER (WHERE pump_rpm IS NULL)        AS missing_rpm
FROM sensor_telemetry_cleaned;

-- All missing value counts should return 0.
