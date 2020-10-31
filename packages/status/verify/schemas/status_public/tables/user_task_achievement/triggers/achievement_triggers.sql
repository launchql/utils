-- Verify schemas/status_public/tables/user_task_achievement/triggers/achievement_triggers  on pg

BEGIN;


SELECT verify_trigger ('status_public.achievement_triggers');

ROLLBACK;
