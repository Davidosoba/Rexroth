-- ============================================================
-- Bosch Rexroth AG | Predictive Maintenance
-- Script 01: Create Tables
-- Database: bosch_maintenance
-- Author: David Osoba | Amdari Work Experience Programme
-- ============================================================

-- Run this script first. equipment_master must be created before
-- the other three tables due to foreign key dependencies.

CREATE TABLE equipment_master (
    machine_id                  VARCHAR(50) PRIMARY KEY,
    installation_date           DATE,
    total_operating_hours       INTEGER,
    fluid_type                  VARCHAR(50),
    last_filter_change_date     DATE,
    maintenance_priority        VARCHAR(20)
);

CREATE TABLE sensor_telemetry (
    telemetry_id        SERIAL PRIMARY KEY,
    timestamp           TIMESTAMP NOT NULL,
    machine_id          VARCHAR(50) REFERENCES equipment_master(machine_id),
    pressure_bar        NUMERIC(8,2),
    temp_celsius        NUMERIC(6,2),
    flow_lpm            NUMERIC(8,2),
    vibration_x_g       NUMERIC(8,4),
    vibration_y_g       NUMERIC(8,4),
    pump_rpm            NUMERIC(8,1),
    is_anomaly          SMALLINT,
    failure_mode        VARCHAR(50),
    rul_hours           NUMERIC(8,2),
    is_sensor_dropout   SMALLINT,
    shift               VARCHAR(20),
    day_of_week         SMALLINT
);

CREATE TABLE failure_labels (
    failure_event_id                VARCHAR(50) PRIMARY KEY,
    machine_id                      VARCHAR(50) REFERENCES equipment_master(machine_id),
    failure_timestamp               DATE,
    failure_mode                    VARCHAR(50),
    degradation_start_timestamp     DATE,
    repair_cost_usd                 NUMERIC(10,2),
    downtime_hours                  NUMERIC(6,2)
);

CREATE TABLE maintenance_log (
    maintenance_id      VARCHAR(50) PRIMARY KEY,
    machine_id          VARCHAR(50) REFERENCES equipment_master(machine_id),
    action_timestamp    TIMESTAMP,
    action_type         VARCHAR(50),
    component_replaced  VARCHAR(50),
    technician_id       VARCHAR(50),
    cost_usd            NUMERIC(10,2)
);
