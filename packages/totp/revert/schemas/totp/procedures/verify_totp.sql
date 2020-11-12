-- Revert schemas/totp/procedures/verify_totp from pg

BEGIN;

DROP FUNCTION totp.verify_totp;

COMMIT;
