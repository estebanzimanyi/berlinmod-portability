-- Copyright(c) MobilityDB Contributors
-- This file is part of MobilityDB documentation.
-- Licensed under Creative Commons Attribution 4.0 International (CC BY 4.0).
--
-- BerlinMOD Q7: What are the licence plate numbers of the passenger cars that
-- reached the points from QueryPoints first of all passenger cars during the
-- complete observation period?
--
-- This is the original BerlinMOD R-benchmark Q7 (a first-arrival ranking),
-- restored and made portable + index-less.  For each query point, among all
-- passenger cars that ever pass exactly through it, report the one(s) with the
-- earliest arrival instant.
--
-- Portable: works unchanged on MobilityDB/PostgreSQL, MobilityDuck/DuckDB,
-- and MobilitySpark/Spark SQL.
--
-- Temporal operations used:
--   eEq(h3indexset, th3index) → boolean        th3 cell-set prefilter.  A
--     point lies in exactly one H3 cell, so a trip can only pass through it
--     while it is in that cell; eEq(p.geom_h3, t.trip_h3) is therefore a
--     sound, index-less prefilter that prunes the cross product without a
--     GiST/SP-GiST index (so it runs the same on every engine).
--   atValues(tgeompoint, geometry) → tgeompoint   restrict the trip to the
--     instants when it is exactly at the point (NULL if it never is).
--   startTimestamp(tgeompoint) → timestamptz      first such instant.

WITH Temp AS (
  SELECT v.licence, p.pointId, p.geomWKT,
         MIN(startTimestamp(atValues(t.trip, p.geom))) AS instant
  FROM   Trips t
  JOIN   Vehicles v   ON v.vehId = t.vehId
  JOIN   QueryPoints p ON eEq(p.geom_h3, t.trip_h3)
  WHERE  v.type = 'passenger'
    AND  atValues(t.trip, p.geom) IS NOT NULL
  GROUP  BY v.licence, p.pointId, p.geomWKT
)
SELECT t1.licence, t1.pointId, t1.geomWKT AS geom, t1.instant
FROM   Temp t1
WHERE  t1.instant <= (
         SELECT MIN(t2.instant) FROM Temp t2 WHERE t1.pointId = t2.pointId)
ORDER  BY t1.pointId, t1.licence;
