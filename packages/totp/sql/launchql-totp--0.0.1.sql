\echo Use "CREATE EXTENSION launchql-totp" to load this file. \quit
CREATE SCHEMA totp;

CREATE FUNCTION totp.urlencode ( in_str text ) RETURNS text AS $EOFCODE$
DECLARE
  _i int4;
  _temp varchar;
  _ascii int4;
  _result text := '';
BEGIN
  FOR _i IN 1..length(in_str)
  LOOP
    _temp := substr(in_str, _i, 1);
    IF _temp ~ '[0-9a-zA-Z:/@._?#-]+' THEN
      _result := _result || _temp;
    ELSE
      _ascii := ascii(_temp);
      IF _ascii > x'07ff'::int4 THEN
        RAISE exception 'won''t deal with 3 (or more) byte sequences.';
      END IF;
      IF _ascii <= x'07f'::int4 THEN
        _temp := '%' || to_hex(_ascii);
      ELSE
        _temp := '%' || to_hex((_ascii & x'03f'::int4) + x'80'::int4);
        _ascii := _ascii >> 6;
        _temp := '%' || to_hex((_ascii & x'01f'::int4) + x'c0'::int4) || _temp;
      END IF;
      _result := _result || upper(_temp);
    END IF;
  END LOOP;
  RETURN _result;
END;
$EOFCODE$ LANGUAGE plpgsql STRICT IMMUTABLE;

CREATE FUNCTION totp.t_unix (  timestamptz ) RETURNS bigint AS $EOFCODE$
SELECT floor(EXTRACT(epoch FROM $1))::bigint;
$EOFCODE$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION totp.n ( t timestamptz, step bigint DEFAULT 30 ) RETURNS bigint AS $EOFCODE$
SELECT floor(totp.t_unix(t) / step)::bigint;
$EOFCODE$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION totp.n_hex ( n bigint ) RETURNS text AS $EOFCODE$
DECLARE
 missing_padding int;
 hext text;
BEGIN
  hext = to_hex(n);
  RETURN lpad(hext, 16, '0');
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION totp.generate_totp_time_key ( totp_interval int DEFAULT 30, from_time timestamptz DEFAULT now() ) RETURNS text AS $EOFCODE$
  SELECT totp.n_hex( totp.n ( from_time, totp_interval ) );
$EOFCODE$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION totp.n_hex_to_8_bytes ( input text ) RETURNS bytea AS $EOFCODE$
DECLARE
  b bytea;
  buf text;
BEGIN
    buf = 'SELECT ''\x' || input || '''::bytea';
    EXECUTE buf INTO b;
    RETURN b;
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION totp.hmac_as_20_bytes ( n_hex bytea, v_secret bytea, v_algo text DEFAULT 'sha1' ) RETURNS bytea AS $EOFCODE$
DECLARE
  v_hmac bytea;
BEGIN
  RETURN hmac(n_hex, v_secret, v_algo);
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION totp.get_offset ( hmac_as_20_bytes bytea ) RETURNS int AS $EOFCODE$
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
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION totp.get_first_4_bytes_from_offset ( hmac_as_20_bytes bytea, v_offset int ) RETURNS int[] AS $EOFCODE$
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
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION totp.apply_binary_to_bytes ( four_bytes int[] ) RETURNS int[] AS $EOFCODE$
BEGIN
  four_bytes[1] = four_bytes[1] & 127; -- x'7f';
  four_bytes[2] = four_bytes[2] & 255; -- x'ff';
  four_bytes[3] = four_bytes[3] & 255; -- x'ff';
  four_bytes[4] = four_bytes[4] & 255; -- x'ff';

  RETURN four_bytes;

END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION totp.compact_bytes_to_int ( four_bytes int[] ) RETURNS int AS $EOFCODE$
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
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION totp.calculate_token ( calcd_int int, totp_length int DEFAULT 6 ) RETURNS text AS $EOFCODE$
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
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION totp.pad_secret ( input bytea, len int ) RETURNS bytea AS $EOFCODE$
DECLARE 
  output bytea;
  orig_length int = octet_length(input);
BEGIN
  IF (orig_length = len) THEN 
    RETURN input;
  END IF;

  -- create blank bytea size of new length
  output = lpad('', len, 'x')::bytea;

  FOR i IN 0 .. len-1 LOOP
    output = set_byte(output, i, get_byte(input, i % orig_length));
  END LOOP;

  RETURN output;
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION totp.base32_to_hex ( input text ) RETURNS text AS $EOFCODE$
DECLARE 
  output text[];
  decoded text = base32.decode(input);
  len int = character_length(decoded);
  hx text;
BEGIN

  FOR i IN 1 .. len LOOP
    hx = to_hex(ascii(substring(decoded from i for 1)))::text;
    IF (character_length(hx) = 1) THEN 
        -- if it is odd number of digits, pad a 0 so it can later 
    		hx = '0' || hx;	
    END IF;
    output = array_append(output, hx);
  END LOOP;

  RETURN array_to_string(output, '');
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION totp.generate_procedural ( totp_secret text, totp_interval int DEFAULT 30, totp_length int DEFAULT 6, time_from timestamptz DEFAULT now(), algo text DEFAULT 'sha1', encoding text DEFAULT NULL ) RETURNS text AS $EOFCODE$
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

  IF (encoding = 'base32') THEN 
    v_secret = ( '\x' || totp.base32_to_hex(totp_secret) )::bytea;
  ELSE 
    v_secret = totp_secret::bytea;
  END IF;

  -- v_secret = totp.pad_secret(v_secret, 20);

  v_hmc = totp.hmac_as_20_bytes( 
    totp.n_hex_to_8_bytes(
      totp.n_hex(n)
    ),
    v_secret,
    algo
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
$EOFCODE$ LANGUAGE plpgsql VOLATILE;

CREATE FUNCTION totp.hotp ( key bytea, c int, digits int DEFAULT 6, hash text DEFAULT 'sha1' ) RETURNS text AS $EOFCODE$
DECLARE
    c BYTEA := '\x' || LPAD(TO_HEX(c), 16, '0');
    mac BYTEA := HMAC(c, key, hash);
    trunc_offset INT := GET_BYTE(mac, length(mac) - 1) % 16;
    result TEXT := SUBSTRING(SET_BIT(SUBSTRING(mac FROM 1 + trunc_offset FOR 4), 7, 0)::TEXT, 2)::BIT(32)::INT % (10 ^ digits)::INT;
BEGIN
    RETURN LPAD(result, digits, '0');
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION totp.generate ( secret text, period int DEFAULT 30, digits int DEFAULT 6, time_from timestamptz DEFAULT now(), hash text DEFAULT 'sha1', encoding text DEFAULT 'base32', clock_offset int DEFAULT 0 ) RETURNS text AS $EOFCODE$
DECLARE
    c INT := FLOOR(EXTRACT(EPOCH FROM time_from) / period)::INT + clock_offset;
    key bytea;
BEGIN

  IF (encoding = 'base32') THEN 
    key = ( '\x' || totp.base32_to_hex(secret) )::bytea;
  ELSE 
    key = secret::bytea;
  END IF;

  RETURN totp.hotp(key, c, digits, hash);
END;
$EOFCODE$ LANGUAGE plpgsql STABLE;

CREATE FUNCTION totp.generate_secret ( hash text DEFAULT 'sha1' ) RETURNS bytea AS $EOFCODE$
BEGIN
    -- See https://tools.ietf.org/html/rfc4868#section-2.1.2
    -- The optimal key length for HMAC is the block size of the algorithm
    CASE
          WHEN hash = 'sha1'   THEN RETURN gen_random_bytes(20); -- = 160 bits
          WHEN hash = 'sha256' THEN RETURN gen_random_bytes(32); -- = 256 bits
          WHEN hash = 'sha512' THEN RETURN gen_random_bytes(64); -- = 512 bits
          ELSE
            RAISE EXCEPTION 'Unsupported hash algorithm for OTP (see RFC6238/4226).';
            RETURN NULL;
    END CASE;
END;
$EOFCODE$ LANGUAGE plpgsql VOLATILE;

CREATE FUNCTION totp.verify ( secret text, check_totp text, period int DEFAULT 30, digits int DEFAULT 6, time_from timestamptz DEFAULT now(), hash text DEFAULT 'sha1', encoding text DEFAULT NULL, clock_offset int DEFAULT 0 ) RETURNS boolean AS $EOFCODE$
  SELECT totp.generate (
    secret,
    period,
    digits,
    time_from,
    hash,
    encoding,
    clock_offset) = check_totp;
$EOFCODE$ LANGUAGE sql;

CREATE FUNCTION totp.url ( email text, totp_secret text, totp_interval int, totp_issuer text ) RETURNS text AS $EOFCODE$
  SELECT
    concat('otpauth://totp/', totp.urlencode (email), '?secret=', totp.urlencode (totp_secret), '&period=', totp.urlencode (totp_interval::text), '&issuer=', totp.urlencode (totp_issuer));
$EOFCODE$ LANGUAGE sql STRICT IMMUTABLE;

CREATE FUNCTION totp.random_base32 ( _length int DEFAULT 16 ) RETURNS text LANGUAGE sql AS $EOFCODE$
  SELECT
    string_agg(('{a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,2,3,4,5,6,7}'::text[])[ceil(random() * 32)], '')
  FROM
    generate_series(1, _length);
$EOFCODE$;