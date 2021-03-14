\echo Use "CREATE EXTENSION launchql-utils" to load this file. \quit
CREATE SCHEMA utils;

GRANT USAGE ON SCHEMA utils TO PUBLIC;

ALTER DEFAULT PRIVILEGES IN SCHEMA utils 
 GRANT EXECUTE ON FUNCTIONS  TO PUBLIC;

CREATE FUNCTION utils.mask_pad ( bitstr text, bitlen int, pad text DEFAULT '0' ) RETURNS text AS $EOFCODE$
  SELECT
    (
      CASE WHEN length(bitstr) > bitlen THEN
        substring(bitstr FROM (length(bitstr) - (bitlen - 1))
          FOR bitlen)
      ELSE
        lpad(bitstr, bitlen, pad)
      END)
$EOFCODE$ LANGUAGE sql;

CREATE FUNCTION utils.bitmask_pad ( bitstr pg_catalog.varbit, bitlen int, pad text DEFAULT '0' ) RETURNS pg_catalog.varbit AS $EOFCODE$
  SELECT
    (
      CASE WHEN length(bitstr) > bitlen THEN
        substring(bitstr::text FROM (length(bitstr) - (bitlen - 1))
          FOR bitlen)
      ELSE
        lpad(bitstr::text, bitlen, pad)
      END)::varbit;
$EOFCODE$ LANGUAGE sql;