-- Verify schemas/totp/procedures/totp_url  on pg

BEGIN;

SELECT verify_function ('totp.totp_url');

ROLLBACK;
