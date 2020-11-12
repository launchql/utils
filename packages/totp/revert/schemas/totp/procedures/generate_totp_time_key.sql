-- Revert schemas/totp/procedures/generate_totp_time_key from pg

BEGIN;

DROP FUNCTION totp.generate_totp_time_key;

COMMIT;
