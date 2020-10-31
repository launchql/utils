-- Revert schemas/status_public/tables/user_task_achievement/triggers/achievement_triggers from pg

BEGIN;

DROP TRIGGER achievement_triggers ON status_public.user_task_achievement;


COMMIT;
