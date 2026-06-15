-- Copyright(c) MobilityDB Contributors
-- This file is part of MobilityDB documentation.
-- Licensed under Creative Commons Attribution 4.0 International (CC BY 4.0).
--
-- BerlinMOD Q5: What is the minimum distance between places where a vehicle
-- with a licence from QueryLicences and another such vehicle have been?
--
-- This is the original BerlinMOD R-benchmark Q5: the minimum SPATIAL distance
-- between the places the two vehicles visited -- regardless of WHEN. In the
-- reference it is ST_Distance(ST_Collect(trajectory(trips1)),
-- ST_Collect(trajectory(trips2))) per pair of licences. (The previous form used
-- nearestApproachDistance, the time-synchronous nearest approach, a different
-- metric that misses pairs whose paths cross at different times.)
--
-- Portable + index-less: minDistance(tgeompoint[], tgeompoint[]) computes
-- exactly ST_Distance(ST_Collect(trajectory(arr1)), ST_Collect(trajectory(arr2)))
-- but uses each input's STBox as a sound lower-bound prefilter and processes
-- candidate pairs in ascending bbox-distance order with short-circuiting, so it
-- needs no GiST/SP-GiST index and runs the same on every engine. Each licence's
-- trips are collected into one array once, then compared pairwise.
--
-- Temporal operations used:
--   minDistance(tgeompoint[], tgeompoint[]) → float8

WITH LicenceTrips AS (
  SELECT l.licenceId, l.licence, array_agg(t.trip) AS trips
  FROM   QueryLicences l
  JOIN   Vehicles v ON v.licence = l.licence
  JOIN   Trips    t ON t.vehId   = v.vehId
  GROUP  BY l.licenceId, l.licence
)
SELECT a.licence AS licence1,
       b.licence AS licence2,
       minDistance(a.trips, b.trips) AS min_dist
FROM   LicenceTrips a
JOIN   LicenceTrips b ON a.licenceId < b.licenceId
ORDER  BY licence1, licence2;
