-- Verify schemas/base32/procedures/bytea  on pg

BEGIN;

SELECT verify_function ('base32.bytea');

ROLLBACK;
