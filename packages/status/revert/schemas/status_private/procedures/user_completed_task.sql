-- Revert schemas/status_private/procedures/user_completed_task from pg

BEGIN;

DROP FUNCTION status_private.user_completed_task;

COMMIT;
