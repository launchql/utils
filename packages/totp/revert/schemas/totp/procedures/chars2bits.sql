-- Revert schemas/totp/procedures/chars2bits from pg

BEGIN;

DROP FUNCTION totp.chars2bits;

COMMIT;
