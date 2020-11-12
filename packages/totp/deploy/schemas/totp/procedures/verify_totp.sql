-- Deploy schemas/totp/procedures/verify_totp to pg
-- requires: schemas/totp/schema
-- requires: schemas/totp/procedures/generate_totp
-- requires: schemas/totp/procedures/generate_totp_time_key

BEGIN;
CREATE FUNCTION totp.verify_totp (totp_secret text, totp_interval int, totp_length int, check_totp text, time_from timestamptz DEFAULT NOW())
  RETURNS boolean
  AS $$
  SELECT totp.generate_totp (
    totp_secret,
    totp_interval,
    totp_length,
    time_from) = check_totp;
$$
LANGUAGE 'sql';
COMMIT;

