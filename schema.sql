-- Copyright(c) MobilityDB Contributors
-- This file is part of MobilityDB documentation.
-- Licensed under Creative Commons Attribution 4.0 International (CC BY 4.0).
--
-- BerlinMOD schema — ONE file run identically by MobilityDB/PostgreSQL,
-- MobilityDuck/DuckDB and MobilitySpark/Spark SQL.
--
-- These are the INPUT tables the raw CSVs load into (no H3 columns). load.sql then
-- builds the indexed Trips / QueryPoints / QueryRegions from them via CREATE TABLE
-- AS SELECT, and the queries read those.
--
-- Column TYPES: tgeompoint, tstzspan, geometry, … are the MobilityDB types,
-- registered identically on MobilityDB/PostgreSQL and MobilityDuck/DuckDB. On
-- MobilitySpark/Spark the same columns are STRING (EWKB-/WKT-compatible hex/text)
-- operated on by UDFs of the same names — until Spark exposes the types as UDTs.
-- load.sql and every query are byte-identical across the three regardless.

CREATE TABLE IF NOT EXISTS Vehicles (
    vehId   integer,
    licence text,
    type    text,
    model   text
);

CREATE TABLE IF NOT EXISTS QueryLicences (
    licenceId integer,
    licence   text,
    vehId     integer
);

CREATE TABLE IF NOT EXISTS QueryInstants (
    instantId integer,
    instant   timestamptz
);

CREATE TABLE IF NOT EXISTS QueryPeriods (
    periodId integer,
    period   tstzspan
);

CREATE TABLE IF NOT EXISTS TripsInput (
    tripId integer,
    vehId  integer,
    trip   tgeompoint        -- raw lat/lon (EPSG:4326) trajectory; H3 built at load
);

CREATE TABLE IF NOT EXISTS QueryPointsInput (
    pointId integer,
    geom    geometry         -- raw lat/lon (EPSG:4326) point
);

CREATE TABLE IF NOT EXISTS QueryRegionsInput (
    regionId integer,
    geom     geometry        -- raw lat/lon (EPSG:4326) region
);
