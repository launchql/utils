-- Verify schemas/totp/procedures/chars2bits  on pg

BEGIN;

SELECT verify_function ('totp.chars2bits');

ROLLBACK;
