-- Verify schemas/totp/procedures/base32_encode  on pg

BEGIN;

SELECT verify_function ('totp.base32_encode');

ROLLBACK;
