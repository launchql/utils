-- Verify schemas/totp/procedures/base32_decode  on pg

BEGIN;

SELECT verify_function ('totp.base32_decode');

ROLLBACK;
