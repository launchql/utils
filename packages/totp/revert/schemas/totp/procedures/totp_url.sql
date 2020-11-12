-- Revert schemas/totp/procedures/totp_url from pg

BEGIN;

DROP FUNCTION totp.totp_url;

COMMIT;
