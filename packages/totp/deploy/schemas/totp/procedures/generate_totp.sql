-- Deploy schemas/totp/procedures/generate_totp to pg
-- requires: schemas/totp/schema
-- requires: schemas/totp/procedures/base32_encode
-- requires: schemas/totp/procedures/base32_decode
-- requires: schemas/totp/procedures/chars2bits
-- requires: schemas/totp/procedures/generate_totp_time_key

BEGIN;
CREATE FUNCTION totp.generate_totp (totp_secret text, totp_interval int default 30, totp_length int default 6, time_from timestamptz DEFAULT NOW())
  RETURNS text
  AS $$
DECLARE
  v_input_check int := length(totp_secret) % 8;
  v_buffer text := '';
  v_b32_secret text;
  v_key text;
  v_totp_time_key text;
  v_hmac text;
  v_offset int;
  v_part1 int;
BEGIN

  IF (time_from IS NULL) THEN
    time_from := NOW();
  END IF;

  IF (totp_length IS NULL) THEN
    totp_length := 6;
  END IF;

  IF (totp_interval IS NULL) THEN
    totp_interval := 30;
  END IF;

  v_totp_time_key := totp.generate_totp_time_key(totp_interval, time_from);

  IF NOT totp_secret ~ '^[a-z2-7]+$' THEN
    RAISE EXCEPTION 'Data contains non-base32 characters';
  END IF;
  IF v_input_check = 1 OR v_input_check = 3 OR v_input_check = 8 THEN
    RAISE EXCEPTION 'Length of data invalid';
  END IF;
  SELECT
    totp.chars2bits (totp_secret) INTO v_buffer;
  IF NOT v_buffer ~ ('0{' || length(v_buffer) % 8 || '}$') THEN
    RAISE EXCEPTION 'PADDING number of bits at the end of output buffer are not all zero';
  END IF;

  v_b32_secret := base32.encode (v_buffer);
  v_key := base32.decode (v_b32_secret);

  -- v_b32_secret := totp.base32_encode (v_buffer);
  -- v_key := totp.base32_decode (v_b32_secret);

  -- TODO ensure we can use md5
  -- https://tools.ietf.org/html/rfc6238
  --  TOTP implementations MAY use HMAC-SHA-256 or HMAC-SHA-512 functions,
  --  based on SHA-256 or SHA-512 [SHA2] hash functions, instead of the
  --  HMAC-SHA-1 function that has been specified for the HOTP computation
  --  in [RFC4226].

  v_hmac := encode(hmac(v_totp_time_key, v_key, 'sha1'), 'hex');
  -- v_hmac := encode(hmac(v_totp_time_key, v_key, 'md5'), 'hex');
  SELECT
    concat('x', lpad(substring(v_hmac FROM '.$'), 8, '0'))::bit(32)::int INTO v_offset;
  SELECT
    concat('x', lpad(substring(v_hmac, v_offset * 2 + 1, 8), 8, '0'))::bit(32)::int INTO v_part1;
  RETURN substring((v_part1 & x'7fffffff'::int)::text FROM '.{' || totp_length || '}$');
END;
$$
LANGUAGE plpgsql
VOLATILE;
COMMIT;

