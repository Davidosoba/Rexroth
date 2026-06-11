-- ============================================================
-- Bosch Rexroth AG | Predictive Maintenance
-- Script 04: Hourly Aggregation View
-- Database: bosch_maintenance
-- Author: David Osoba | Amdari Work Experience Programme
-- ============================================================

-- This script creates the sensor_telemetry_hourly view.
-- It aggregates 864,000 minute-level sensor readings from
-- sensor_telemetry_cleaned into 14,400 hourly summaries
-- (one row per machine per hour).

-- PURPOSE:
-- Minute-level data is too granular for trend visualisations
-- in Power BI. Hourly aggregation smooths noise while
-- preserving meaningful patterns in sensor behaviour over time.

-- AGGREGATION LOGIC:
-- Numeric sensors   → AVG, MIN, MAX per hour
-- Anomaly/dropout   → SUM (count of events) + AVG (rate/proportion)
-- Categorical cols  → MODE() picks the most frequent value in that hour
-- RUL               → AVG and MIN (min captures closest point to failure)

-- NOTE: This view depends on sensor_telemetry_cleaned.
--       Run script 03 before this script.

-- If the view already exists, drop it first before recreating.
-- DROP VIEW sensor_telemetry_hourly;

CREATE VIEW sensor_telemetry_hourly AS
SELECT
    machine_id,
    DATE_TRUNC('hour', timestamp)                       AS hour_timestamp,

    -- Pressure
    ROUND(AVG(pressure_bar)::NUMERIC, 2)                AS avg_pressure,
    ROUND(MIN(pressure_bar)::NUMERIC, 2)                AS min_pressure,
    ROUND(MAX(pressure_bar)::NUMERIC, 2)                AS max_pressure,

    -- Temperature
    ROUND(AVG(temp_celsius)::NUMERIC, 2)                AS avg_temp,
    ROUND(MIN(temp_celsius)::NUMERIC, 2)                AS min_temp,
    ROUND(MAX(temp_celsius)::NUMERIC, 2)                AS max_temp,

    -- Flow rate
    ROUND(AVG(flow_lpm)::NUMERIC, 2)                    AS avg_flow,
    ROUND(MIN(flow_lpm)::NUMERIC, 2)                    AS min_flow,
    ROUND(MAX(flow_lpm)::NUMERIC, 2)                    AS max_flow,

    -- Vibration (X axis only — X and Y are effectively collinear,
    -- avg difference of 0.0078g across 864,000 rows)
    ROUND(AVG(vibration_x_g)::NUMERIC, 4)               AS avg_vibration_x,
    ROUND(MAX(vibration_x_g)::NUMERIC, 4)               AS max_vibration_x,

    -- Pump RPM
    ROUND(AVG(pump_rpm)::NUMERIC, 1)                    AS avg_rpm,
    ROUND(MIN(pump_rpm)::NUMERIC, 1)                    AS min_rpm,
    ROUND(MAX(pump_rpm)::NUMERIC, 1)                    AS max_rpm,

    -- Anomaly summary
    SUM(is_anomaly)                                     AS total_anomalies,
    ROUND(AVG(is_anomaly)::NUMERIC, 4)                  AS anomaly_rate,

    -- Sensor dropout summary
    SUM(is_sensor_dropout)                              AS total_dropouts,

    -- Remaining Useful Life
    ROUND(AVG(rul_hours)::NUMERIC, 2)                   AS avg_rul_hours,
    ROUND(MIN(rul_hours)::NUMERIC, 2)                   AS min_rul_hours,

    -- Dominant failure mode in that hour (most frequent non-null value)
    MODE() WITHIN GROUP (ORDER BY failure_mode)         AS dominant_failure_mode,

    -- Dominant shift in that hour
    MODE() WITHIN GROUP (ORDER BY shift)                AS shift,

    -- Number of minute-level readings in that hour (should be ~60)
    COUNT(*)                                            AS reading_count

FROM sensor_telemetry_cleaned
GROUP BY machine_id, DATE_TRUNC('hour', timestamp)
ORDER BY machine_id, hour_timestamp;


-- ─────────────────────────────────────────
-- VALIDATION: Confirm expected row count
-- ─────────────────────────────────────────

SELECT
    COUNT(*)                    AS total_hourly_rows,
    COUNT(DISTINCT machine_id)  AS machines,
    MIN(hour_timestamp)         AS earliest_hour,
    MAX(hour_timestamp)         AS latest_hour
FROM sensor_telemetry_hourly;

-- Expected: ~14,400 rows | 10 machines | Jan 2024 to Feb 2024
