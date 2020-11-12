-- Revert schemas/totp/procedures/base32_encode from pg

BEGIN;

DROP FUNCTION totp.base32_encode;

COMMIT;
