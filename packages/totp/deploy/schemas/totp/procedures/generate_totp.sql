-- Deploy schemas/totp/procedures/generate_totp to pg
-- requires: schemas/totp/schema
-- requires: schemas/totp/procedures/base32_encode
-- requires: schemas/totp/procedures/base32_decode
-- requires: schemas/totp/procedures/chars2bits
-- requires: schemas/totp/procedures/generate_totp_time_key

BEGIN;

-- https://www.youtube.com/watch?v=VOYxF12K1vE
-- https://tools.ietf.org/html/rfc6238
-- THEY HAVE PSUEDO code inside
-- http://blog.tinisles.com/2011/10/google-authenticator-one-time-password-algorithm-in-javascript/

-- THIS HAS A TON
-- https://rosettacode.org/wiki/Time-based_one-time_password_algorithm

CREATE FUNCTION totp.t_unix (
  timestamptz
)
  RETURNS bigint
  AS $$
SELECT floor(EXTRACT(epoch FROM $1))::bigint;
$$
LANGUAGE sql IMMUTABLE;

CREATE FUNCTION totp.n (
  t timestamptz,
  step bigint default 30
)
  RETURNS bigint
  AS $$
SELECT floor(totp.t_unix(t) / step)::bigint;
$$
LANGUAGE sql IMMUTABLE;

CREATE FUNCTION totp.n_hex (
  n int
)
  RETURNS text
  AS $$
DECLARE
 missing_padding int;
 hext text;
BEGIN
    hext = to_hex(n);
    missing_padding = character_length(hext) % 16;
    if missing_padding != 0 THEN
      hext = lpad('', (16 - missing_padding), '0') || hext;
    END IF;
  RETURN hext;
END;
$$
LANGUAGE plpgsql
IMMUTABLE;

 -- '0000000003114810' -> '\x0000000003114810'::bytea
CREATE FUNCTION totp.n_hex_to_8_bytes(
  input text
) returns bytea as $$
DECLARE
  b bytea;
  buf text;
BEGIN
    buf = 'SELECT ''\x' || input || '''::bytea';
    EXECUTE buf INTO b;
    RETURN b;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;

CREATE FUNCTION totp.hmac_as_20_bytes(
  n_hex bytea,
  v_secret bytea
) returns bytea as $$
DECLARE
  v_hmac bytea;
BEGIN
  RETURN hmac(n_hex, v_secret, 'sha1'::text);
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;

CREATE FUNCTION totp.get_offset (
  hmac_as_20_bytes bytea
) returns int as $$
DECLARE
  v_hmac bytea;
  v_str text;
  buf text;
  ch text;
  i int;
BEGIN

    -- get last char (or last 4 bits as int)
    ch = right(hmac_as_20_bytes::text, 1); 
    buf = 'SELECT x''' || ch || '''::int';
    EXECUTE buf INTO i;
    RETURN i;

    -- TEST BELOW FOR MORE CASES for now I'm doing the simpler version

    -- 160 bits in 20 bytes... so get last 4 bits:
    -- you may wonder why these numbers?
    -- e.g., 0x9A => A => 0b1010 => 10 (int)
    -- it's not x x x x 1 0 1 0 ...
    -- it's actually 
        --  A                   9
    -- [0] [1] [0] [1] [ ] [ ] [ ] [ ] 
    v_str = concat(
      '0000',
      get_bit( hmac_as_20_bytes, 155),
      get_bit( hmac_as_20_bytes, 154),
      get_bit( hmac_as_20_bytes, 153),
      get_bit( hmac_as_20_bytes, 152)
    );

    buf = 'SELECT B''' || v_str || '''::int';
    EXECUTE buf INTO i;

    RETURN i;

END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;



CREATE FUNCTION totp.get_first_4_bytes_from_offset (
  hmac_as_20_bytes bytea,
  v_offset int
) returns int[] as $$
DECLARE
  a int;
  b int;
  c int;
  d int;
BEGIN

  a = get_byte(hmac_as_20_bytes, v_offset);
  b = get_byte(hmac_as_20_bytes, v_offset + 1);
  c = get_byte(hmac_as_20_bytes, v_offset + 2);
  d = get_byte(hmac_as_20_bytes, v_offset + 3);

  RETURN ARRAY[a,b,c,d]::int[];

END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;

CREATE FUNCTION totp.apply_binary_to_bytes (
  four_bytes int[]
) returns int[] as $$
BEGIN
  four_bytes[1] = four_bytes[1] & 127; -- x'7f';
  four_bytes[2] = four_bytes[2] & 255; -- x'ff';
  four_bytes[3] = four_bytes[3] & 255; -- x'ff';
  four_bytes[4] = four_bytes[4] & 255; -- x'ff';

  RETURN four_bytes;

END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;

CREATE FUNCTION totp.compact_bytes_to_int (
  four_bytes int[]
) returns int as $$
DECLARE 
  buf text;
  i int;
BEGIN
  buf = 
   to_hex(four_bytes[1]) ||
   to_hex(four_bytes[2]) ||
   to_hex(four_bytes[3]) ||
   to_hex(four_bytes[4]);

  buf = 'SELECT x''' || buf || '''::int';
  EXECUTE buf INTO i;
  RETURN i;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;

CREATE FUNCTION totp.calculate_token (
  calcd_int int,
  totp_length int default 6
) returns text as $$
DECLARE 
  buf text;
  i int;
  s text;
  missing_padding int;
BEGIN
   i = calcd_int % (10^totp_length)::int;
   s = i::text;

   -- if token size < totp_len, padd with zeros
   missing_padding = character_length(s) % totp_length;
   if missing_padding != 0 THEN
     s = lpad('', (totp_length - missing_padding), '0') || s;
   END IF;

   RETURN s;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;


CREATE FUNCTION totp.generate_totp_token (
  totp_secret text,
  totp_interval int default 30,
  totp_length int default 6,
  time_from timestamptz DEFAULT NOW()
) returns text as $$
DECLARE 
  v_bytes_int int;
  n int;
  v_hmc bytea;
  v_offset int;

  v_secret bytea;
BEGIN
  n = totp.n(
    time_from,
    totp_interval
  );

  -- v_secret = base32.decode(totp_secret)::bytea;
  -- v_secret = base32.encode(totp_secret)::bytea;
  v_secret = totp_secret::bytea;

  v_hmc = totp.hmac_as_20_bytes( 
    totp.n_hex_to_8_bytes(
      totp.n_hex(n)
    ),
    v_secret
  );

  v_offset = totp.get_offset(
    v_hmc
  );

  v_bytes_int = totp.compact_bytes_to_int( 
    totp.apply_binary_to_bytes(
      totp.get_first_4_bytes_from_offset(
        v_hmc,
        v_offset
      )
    )
  );

  RETURN totp.calculate_token(
    v_bytes_int,
    totp_length
  );

END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;















-- OTHER ATTEMPTS BELOW


CREATE FUNCTION totp.counter (
  v_time int,
  v_epoch int default 0,
  v_step int default 30
)
  RETURNS int
  AS $$
DECLARE
BEGIN
  IF (v_time IS NULL) THEN 
    v_time = floor(EXTRACT(epoch FROM NOW())*1000); -- ~equiv to Date.now() is JS
  ELSE
    v_time = v_time * 1000;
  END IF;

  RETURN floor((v_time - v_epoch) / v_step / 1000);
END;
$$
LANGUAGE plpgsql
VOLATILE; -- IMMUTABLE?


CREATE FUNCTION totp.digest (
  v_secret text,
  v_counter int
)
  RETURNS text
  AS $$
DECLARE
   i int;
   tmp int;
   buf bytea;

   v_hmac text;
BEGIN

  -- "blank" 8 bytes please
  -- buf = lpad('', 8, 'x')::bytea;
  buf = ('\x' || lpad('', (8)*2, '0'))::bytea;
  tmp = v_counter;
  FOR i IN 0 .. 7 LOOP
    -- mask 0xff over number to get last 8
    -- buf[7 - i] = tmp & 0xff;
    buf = set_bit(buf, 7-i, tmp & 255);
    -- shift 8 and get ready to loop over the next batch of 8
    tmp = tmp >> 8;
  END LOOP;

  v_hmac = encode(hmac(buf::text, v_secret::text, 'sha1'::text), 'hex');

  RETURN v_hmac;
  
END;
$$
LANGUAGE plpgsql
VOLATILE; -- IMMUTABLE?

CREATE FUNCTION totp.byte_secret (
  v_secret text
)
  RETURNS text
  AS $$
DECLARE
 missing_padding int;
BEGIN
    missing_padding = character_length(v_secret) % 8;
    if missing_padding != 0 THEN
      v_secret = v_secret || lpad('', (8 - missing_padding), '=');
    END IF;
    -- but was this even a 32 encoded?
    RETURN base32.decode(v_secret);
  RETURN v_secret;
END;
$$
LANGUAGE plpgsql
VOLATILE; -- IMMUTABLE?


CREATE FUNCTION totp.gtotp (
  v_secret text,
  v_time int
)
  RETURNS text
  AS $$
DECLARE
  v_counter int = totp.counter(
      v_step := 30,
      v_epoch := 0,
      v_time := v_time
  );
BEGIN

  RETURN totp.digest( 
    v_secret := v_secret,
    v_counter := v_counter  
  );

END;
$$
LANGUAGE plpgsql
VOLATILE; -- IMMUTABLE?




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
  v_b32_secret := 'JBSWY3DPEHPK3PXP';
  -- v_b32_secret := base32.encode (totp_secret);
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

