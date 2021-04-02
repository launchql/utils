-- Deploy launchql-ext-defaults:defaults/public to pg

BEGIN;
DO $$
DECLARE
  sql text;
BEGIN
  SELECT
    format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database()) INTO sql;
  EXECUTE sql;
END
$$;

-- postgis, unaccent, hstore: all of these need access
ALTER DEFAULT PRIVILEGES GRANT EXECUTE ON FUNCTIONS TO PUBLIC;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
COMMIT;

