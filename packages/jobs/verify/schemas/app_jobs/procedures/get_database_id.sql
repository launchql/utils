-- Verify schemas/app_jobs/procedures/get_database_id  on pg

BEGIN;

SELECT verify_function ('app_jobs.get_database_id');

ROLLBACK;
