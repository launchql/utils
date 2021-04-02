\echo Use "CREATE EXTENSION launchql-ext-defaults" to load this file. \quit
DO $$
  DECLARE
  sql text;
BEGIN
  SELECT
    format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database()) INTO sql;
  EXECUTE sql;
END $$;

ALTER DEFAULT PRIVILEGES GRANT EXECUTE ON FUNCTIONS  TO PUBLIC;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;