-- Revert schemas/totp/procedures/base32_decode from pg

BEGIN;

DROP FUNCTION totp.base32_decode;

COMMIT;
