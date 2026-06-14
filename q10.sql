-- Copyright(c) MobilityDB Contributors
-- This file is part of MobilityDB documentation.
-- Licensed under Creative Commons Attribution 4.0 International (CC BY 4.0).
--
-- BerlinMOD Q10: When did the vehicles with licences from QueryLicences meet
-- other vehicles (within 3 m) and what are the other vehicle IDs?
--
-- Portable: works unchanged on MobilityDB/PostgreSQL, MobilityDuck/DuckDB,
-- and MobilitySpark/Spark SQL.
--
-- Temporal operations used:
--   tDwithinPairs(tgeompoint[], tgeompoint[], float) → setof (i, j, periods)
--     The NxN-array form of tDwithin + whenTrue.  Given two arrays of trips it
--     returns, for every pair that ever came within the distance, the 1-based
--     index pair (i, j) and the tstzspanset of periods during which they did —
--     computing the STBox prefilter, the temporal distance, and the period
--     extraction once in C over the whole cross product instead of one
--     expandSpace/tDwithin/whenTrue per candidate pair.  Only pairs with a
--     non-empty period set are emitted, so the former "periods IS NOT NULL"
--     filter is implicit.
--
-- Side 1 is the trips of the QueryLicences vehicles, side 2 is all trips; the
-- result indices i, j are 1-based into the two parallel arrays.  vehIds1[i] <>
-- vehIds2[j] reproduces the former t1.vehId <> t2.vehId.

WITH Sel AS (        -- trips of the QueryLicences vehicles (side 1)
  SELECT array_agg(t.trip    ORDER BY t.tripId) AS trips,
         array_agg(l.licence ORDER BY t.tripId) AS licences,
         array_agg(v.vehId   ORDER BY t.tripId) AS vehIds,
         array_agg(t.tripId  ORDER BY t.tripId) AS tripIds
  FROM   QueryLicences l
  JOIN   Vehicles v ON v.licence = l.licence
  JOIN   Trips    t ON t.vehId   = v.vehId
),
AllTrips AS (        -- every trip (side 2)
  SELECT array_agg(t.trip   ORDER BY t.tripId) AS trips,
         array_agg(t.vehId  ORDER BY t.tripId) AS vehIds,
         array_agg(t.tripId ORDER BY t.tripId) AS tripIds
  FROM   Trips t
)
SELECT s.licences[p.i] AS licence1,
       a.vehIds[p.j]   AS car2Id,
       p.periods       AS periods
FROM   Sel s, AllTrips a,
       tDwithinPairs(s.trips, a.trips, 3.0) AS p(i, j, periods)
WHERE  s.vehIds[p.i] <> a.vehIds[p.j]
ORDER  BY licence1, car2Id, s.tripIds[p.i], a.tripIds[p.j];
