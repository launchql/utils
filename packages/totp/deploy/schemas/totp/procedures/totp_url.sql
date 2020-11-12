-- Deploy schemas/totp/procedures/totp_url to pg
-- requires: schemas/totp/schema
-- requires: schemas/totp/procedures/urlencode

BEGIN;
CREATE FUNCTION totp.totp_url (email text, totp_secret text, totp_interval int, totp_issuer text)
  RETURNS text
  AS $$
  SELECT
    concat('otpauth://totp/', totp.urlencode (email), '?secret=', totp.urlencode (totp_secret), '&period=', totp.urlencode (totp_interval::text), '&issuer=', totp.urlencode (totp_issuer));
$$
LANGUAGE 'sql'
STRICT IMMUTABLE;
COMMIT;

