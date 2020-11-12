-- Deploy schemas/totp/procedures/generate_totp_time_key to pg
-- requires: schemas/totp/schema

BEGIN;
CREATE FUNCTION totp.generate_totp_time_key (
  totp_interval int DEFAULT 30,
  from_time timestamptz DEFAULT NOW()
)
  RETURNS text
  AS $$
  SELECT
    lpad(to_hex(floor(extract(epoch FROM from_time) / totp_interval)::int), 16, '0');
$$
LANGUAGE 'sql'
STABLE;
COMMIT;

