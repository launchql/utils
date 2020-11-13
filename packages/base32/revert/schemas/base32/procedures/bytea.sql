-- Revert schemas/base32/procedures/bytea from pg

BEGIN;

DROP FUNCTION base32.bytea;

COMMIT;
