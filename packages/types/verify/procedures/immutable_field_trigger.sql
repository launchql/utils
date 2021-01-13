-- Verify procedures/immutable_field_trigger  on pg

BEGIN;

SELECT verify_function ('public.immutable_field_trigger');

ROLLBACK;
