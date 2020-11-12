-- Verify schemas/totp/procedures/verify_totp  on pg

BEGIN;

SELECT verify_function ('totp.verify_totp');

ROLLBACK;
