-- Verify schemas/totp/procedures/generate_totp_time_key  on pg

BEGIN;

SELECT verify_function ('totp.generate_totp_time_key');

ROLLBACK;
