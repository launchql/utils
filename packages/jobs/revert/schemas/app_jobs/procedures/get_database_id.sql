-- Revert schemas/app_jobs/procedures/get_database_id from pg

BEGIN;

DROP FUNCTION app_jobs.get_database_id;

COMMIT;
