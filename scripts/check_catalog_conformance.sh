#!/bin/bash
# Catalog-conformance guard for the BerlinMOD portable suite.
#
# Every function / operator / column the canonical queries use must resolve
# against the MEOS catalog (the loaded MobilityDB extension + schema.sql +
# portable_aliases.sql + load.sql). EXPLAIN parses and plans each query
# without any data, so a name absent from the catalog fails fast. This is the
# guard against the hand-written queries drifting from the single MEOS source
# of truth (e.g. a MEOS rename that the queries were not updated for).
#
# Usage: scripts/check_catalog_conformance.sh [dbname]
# Env:   PGHOST/PGPORT/PGUSER as needed; a MobilityDB-enabled PostgreSQL.
set -u
SUITE="$(cd "$(dirname "$0")/.." && pwd)"
DB="${1:-berlinmod_conformance}"
run(){ psql -d "$1" -qtA "${@:2}"; }
psql -qtAc "DROP DATABASE IF EXISTS $DB;" -d postgres >/dev/null 2>&1
psql -qtAc "CREATE DATABASE $DB;"        -d postgres >/dev/null 2>&1
run "$DB" -c "CREATE EXTENSION mobilitydb CASCADE;" >/dev/null 2>&1
run "$DB" -f "$SUITE/schema.sql"          >/dev/null 2>&1
[ -f "$SUITE/portable_aliases.sql" ] && run "$DB" -f "$SUITE/portable_aliases.sql" >/dev/null 2>&1
run "$DB" -f "$SUITE/load.sql"            >/dev/null 2>&1
fail=0
for q in $(ls "$SUITE"/q??.sql "$SUITE"/qrt.sql 2>/dev/null | sort -u); do
  name=$(basename "$q" .sql); tmp=$(mktemp --suffix=.sql)
  { printf 'EXPLAIN '; grep -vE '^[[:space:]]*--' "$q"; } > "$tmp"
  err=$(run "$DB" -f "$tmp" 2>&1 | grep -iE 'does not exist|no function matches|no operator matches' | head -1)
  rm -f "$tmp"
  if [ -n "$err" ]; then printf '  FAIL %-5s %s\n' "$name" "${err#ERROR:  }"; fail=$((fail+1))
  else printf '  ok   %-5s\n' "$name"; fi
done
echo "--- $fail query file(s) use names absent from the catalog ---"
psql -qtAc "DROP DATABASE IF EXISTS $DB;" -d postgres >/dev/null 2>&1
exit $fail
