-- Copyright(c) MobilityDB Contributors
-- This file is part of MobilityDB documentation.
-- Licensed under Creative Commons Attribution 4.0 International (CC BY 4.0).
--
-- BerlinMOD canonical loader — ONE file run identically by MobilityDB/PostgreSQL,
-- MobilityDuck/DuckDB and MobilitySpark/Spark SQL.
--
-- The shared CSVs carry only RAW lat/lon trajectories/geometries (no H3 columns),
-- as a real GPS/AIS ingest would. Each engine first reads those CSVs into the
-- input tables defined in schema.sql (TripsInput / QueryPointsInput /
-- QueryRegionsInput + the non-derived tables) using its own CSV reader — the one
-- engine-specific step, because COPY / read_csv / spark.read have no common
-- syntax. Everything below, and every query, is identical across the three.
--
-- This builds the H3 cell-set prefilter index from the raw lat/lon via
-- CREATE TABLE AS SELECT (supported by all three engines). The build expressions
-- th3index(trip, R) and geoToH3IndexSet(geom, R) are MobilityDB functions exposed
-- identically on every platform, so the logic is canonical.
--
-- H3 RESOLUTION (R) — the single tuning knob, default 7 (cell edge ≈ 1.2 km),
-- sound for the 3–10 m dWithin thresholds the queries use. Geometries are lon/lat
-- (EPSG:4326), which H3 requires, so the build never reprojects.
--
-- The th3 prefilter is then the pure cell-membership test
--   eEq(<static>.geom_h3, t.trip_h3)
-- carried by q02/q04/q11–q17, with no per-query geoToH3IndexSet or transform.

CREATE TABLE Trips AS
  SELECT tripId, vehId, trip,
         th3index(trip, 7) AS trip_h3
  FROM   TripsInput;

CREATE TABLE QueryPoints AS
  SELECT pointId, geom,
         geoToH3IndexSet(geom, 7) AS geom_h3,
         asEWKT(geom) AS geomWKT
  FROM   QueryPointsInput;

CREATE TABLE QueryRegions AS
  SELECT regionId, geom,
         geoToH3IndexSet(geom, 7) AS geom_h3
  FROM   QueryRegionsInput;
