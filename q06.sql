-- Copyright(c) MobilityDB Contributors
-- This file is part of MobilityDB documentation.
-- Licensed under Creative Commons Attribution 4.0 International (CC BY 4.0).
--
-- BerlinMOD Q6: Pairs of trucks that ever came within 10 m of each other.
--
-- Portable: works unchanged on MobilityDB/PostgreSQL, MobilityDuck/DuckDB,
-- and MobilitySpark/Spark SQL.
--
-- Temporal operations used:
--   eDwithinPairs(tgeompoint[], tgeompoint[], float8) → setof (i, j)
--     The NxN-array form of eDwithin.  Given two arrays of trips it returns
--     every 1-based index pair (i, j) whose trips ever came within the
--     distance of each other, performing the STBox prefilter and the exact
--     ever-distance test once in C over the whole cross product — instead of
--     a SQL self-join that evaluates one expandSpace/eDwithin per candidate
--     pair.  The pair set includes self pairs and both orders.
--
-- The truck trips are collected once into parallel arrays of trip / licence /
-- vehicle id.  eDwithinPairs returns index pairs into them; vehIds[i] <
-- vehIds[j] keeps one row per unordered distinct-vehicle pair (the former
-- v1.vehId < v2.vehId) and drops the self pairs.

WITH Trucks AS (
  SELECT array_agg(t.trip    ORDER BY t.tripId) AS trips,
         array_agg(v.licence ORDER BY t.tripId) AS licences,
         array_agg(v.vehId   ORDER BY t.tripId) AS vehIds
  FROM   Vehicles v
  JOIN   Trips t ON t.vehId = v.vehId
  WHERE  v.type = 'truck'
)
SELECT k.licences[p.i] AS licence1,
       k.licences[p.j] AS licence2
FROM   Trucks k,
       eDwithinPairs(k.trips, k.trips, 10.0) AS p(i, j)
WHERE  k.vehIds[p.i] < k.vehIds[p.j]
ORDER  BY licence1, licence2;
