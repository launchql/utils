-- Revert procedures/immutable_field_trigger from pg

BEGIN;

DROP FUNCTION public.immutable_field_trigger;

COMMIT;
