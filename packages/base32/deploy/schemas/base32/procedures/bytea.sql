-- Deploy schemas/base32/procedures/bytea to pg

-- requires: schemas/base32/schema

BEGIN;

-- THIS FILE IS WIP, not yet used. 
-- currently, the string-based version is all that works currently

CREATE FUNCTION base32.string_to_bytea(
  input text
) returns bytea as $$
DECLARE
  i int;
  codes int[];
  output bytea;
  len int = character_length(input);
BEGIN
  RETURN input::bytea;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;

CREATE FUNCTION base32.bytea_to_ascii(
  input bytea
) returns int[] as $$
DECLARE
  i int;
  codes int[];
  len int = octet_length(input);
BEGIN
  FOR i IN 0 .. len-1 LOOP
    codes = array_append(codes, get_byte( input, i ));
  END LOOP;
  RETURN codes;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;

CREATE FUNCTION base32.bytea_to_string(
  input bytea
) returns text as $$
  SELECT encode(input, 'escape');
$$
LANGUAGE 'sql' IMMUTABLE;

-- NOT USED since we can use native
CREATE FUNCTION base32.bytea_to_str(
  input bytea
) returns text as $$
DECLARE
  i int;
  codes int[];
  output text;
  len int = octet_length(input);
BEGIN
  -- get ascii codes
  codes = base32.bytea_to_ascii(input);

  -- convert to string
  FOR i IN 1 .. len LOOP
    output = concat(output, chr(codes[i]) );
  END LOOP;

  RETURN output;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;

-- to groups of 5

CREATE FUNCTION base32.to_groups(
  input bytea 
) returns text as $$
DECLARE
  i int;
  output bytea;
  bytes bytea;
  len int = octet_length(input);
  nlen int;

  bitlength int;
  nbitlength int;
  byte_to_write int;
  byte_to_read int;
  bit_to_write int;
  bit_to_read int;
  bits_left int;
  mod5 int;
  starting_bit int;

  out int[];
BEGIN
  IF ( len % 5 = 0 ) THEN 
    RETURN input;
  END IF;

  nlen = len + 5 - (len % 5);

  -- create blank bytea size of new length
  output = lpad('', nlen, 'x')::bytea;

  FOR i IN 0 .. len-1 LOOP
    output = set_byte(output, i, get_byte(input, i));
  END LOOP;

  FOR i IN 1 .. 5 - (len % 5) LOOP
    output = set_byte(output, i+len-1, 255);
  END LOOP;

  -- 2 chars required to represent each byte ( 2 * nlen)
  -- '\x0000000000'::bytea
  -- bytes = ('\x' || lpad('', nlen*2, '0'))::bytea;

  bitlength = len * 8;
  nbitlength = nlen * 8;
  
  -- 2 chars for each byte needed
  -- num bytes = nbitlength / 5

  bits_left = 8;
  byte_to_write = -1;
  bit_to_write = 0;
  bit_to_read = 4;
  starting_bit = 4;

  bytes = ('\x' || lpad('', (nbitlength/5)*2, '0'))::bytea;
  FOR i IN 0 .. nbitlength-1 LOOP
    mod5 = i % 5;
    IF (mod5 = 0) THEN 
      byte_to_write = byte_to_write + 1;
      IF (i != 0) THEN 
        starting_bit = starting_bit + 5;
        bit_to_read = starting_bit;
      END IF;
    END IF;

    bit_to_write = (byte_to_write * 8) + mod5;

    IF (bit_to_read < bitlength) THEN 
      bytes = set_bit(bytes, bit_to_write, get_bit(input, bit_to_read));
    ELSE
      bytes = set_bit(bytes, bit_to_write, 0);
    END IF;

    bit_to_read = bit_to_read - 1;
    bits_left = bits_left - 1;
    IF (bits_left < 0) THEN 
      bits_left = 8;
    END IF;
  END LOOP;

  -- RETURN encode( bytes, 'escape' );

  FOR i IN 0 .. octet_length(bytes)-1 LOOP
    out = array_append(out, get_byte(bytes, i));
  END LOOP;

  RETURN array_to_string(out, '-');

  -- RETURN get_byte(bytes, 0);

  -- RETURN base32.bytea_to_string(bytes);

  -- RETURN concat(len::text, ' | ', nlen::text);

  -- RETURN output;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;


COMMIT;
