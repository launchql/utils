\echo Use "CREATE EXTENSION launchql-base32" to load this file. \quit
CREATE SCHEMA base32;

CREATE FUNCTION base32.string_to_bytea ( input text ) RETURNS bytea AS $EOFCODE$
DECLARE
  i int;
  codes int[];
  output bytea;
  len int = character_length(input);
BEGIN
  RETURN input::bytea;
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.bytea_to_ascii ( input bytea ) RETURNS int[] AS $EOFCODE$
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
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.bytea_to_string ( input bytea ) RETURNS text AS $EOFCODE$
  SELECT encode(input, 'escape');
$EOFCODE$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION base32.bytea_to_str ( input bytea ) RETURNS text AS $EOFCODE$
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
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.to_groups ( input bytea ) RETURNS text AS $EOFCODE$
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
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.binary_to_int ( input text ) RETURNS int AS $EOFCODE$
DECLARE
  i int;
  buf text;
BEGIN
    buf = 'SELECT B''' || input || '''::int';
    EXECUTE buf INTO i;
    RETURN i;
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.to_ascii ( input text ) RETURNS int[] AS $EOFCODE$
DECLARE
  i int;
  output int[];
BEGIN
  FOR i IN 1 .. character_length(input) LOOP
    output = array_append(output, ascii(substring(input from i for 1)));
  END LOOP;
  RETURN output;
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.to_binary ( input int ) RETURNS text AS $EOFCODE$
DECLARE
  i int = 1;
  j int = 0;
  output char[] = ARRAY['x', 'x', 'x', 'x', 'x', 'x', 'x', 'x'];
BEGIN
  WHILE i < 256 LOOP 
    output[8-j] = (CASE WHEN (input & i) > 0 THEN '1' ELSE '0' END)::char;
    i = i << 1;
    j = j + 1;
  END LOOP;
  RETURN array_to_string(output, '');
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.to_binary ( input int[] ) RETURNS text[] AS $EOFCODE$
DECLARE
  i int;
  output text[];
BEGIN
  FOR i IN 1 .. cardinality(input) LOOP
    output = array_append(output, base32.to_binary(input[i]));  
  END LOOP;
  RETURN output;
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.to_groups ( input text[] ) RETURNS text[] AS $EOFCODE$
DECLARE
  i int;
  output text[];
  len int = cardinality(input);
BEGIN
  IF ( len % 5 = 0 ) THEN 
    RETURN input;
  END IF;
  FOR i IN 1 .. 5 - (len % 5) LOOP
    input = array_append(input, 'xxxxxxxx');
  END LOOP;
  RETURN input;
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.string_nchars (  text,  int ) RETURNS text[] AS $EOFCODE$
SELECT ARRAY(SELECT substring($1 from n for $2)
  FROM generate_series(1, length($1), $2) n);
$EOFCODE$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION base32.to_chunks ( input text[] ) RETURNS text[] AS $EOFCODE$
DECLARE
  i int;
  output text[];
  str text;
  len int = cardinality(input);
BEGIN
  RETURN base32.string_nchars(array_to_string(input, ''), 5);
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.fill_chunks ( input text[] ) RETURNS text[] AS $EOFCODE$
DECLARE
  i int;
  output text[];
  chunk text;
  len int = cardinality(input);
BEGIN
  FOR i IN 1 .. len LOOP 
    chunk = input[i];
    IF (chunk ~* '[0-1]+') THEN 
      chunk = replace(chunk, 'x', '0');
    END IF;
    output = array_append(output, chunk);
  END LOOP;
  RETURN output;
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.to_decimal ( input text[] ) RETURNS text[] AS $EOFCODE$
DECLARE
  i int;
  output text[];
  chunk text;
  buf text;
  len int = cardinality(input);
BEGIN
  FOR i IN 1 .. len LOOP 
    chunk = input[i];
    IF (chunk ~* '[x]+') THEN 
      chunk = '=';
    ELSE
      chunk = base32.binary_to_int(input[i])::text;
    END IF;
    output = array_append(output, chunk);
  END LOOP;
  RETURN output;
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.base32_alphabet ( input int ) RETURNS char(1) AS $EOFCODE$
DECLARE
  alphabet text[] = ARRAY[
    'A', 'B', 'C', 'D', 'E', 'F',
    'G', 'H', 'I', 'J', 'K', 'L',
    'M', 'N', 'O', 'P', 'Q', 'R',
    'S', 'T', 'U', 'V', 'W', 'X',
    'Y', 'Z', '2', '3', '4', '5',
    '6', '7'
  ]::text;
BEGIN
  RETURN alphabet[input+1];
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.to_base32 ( input text[] ) RETURNS text AS $EOFCODE$
DECLARE
  i int;
  output text[];
  chunk text;
  buf text;
  len int = cardinality(input);
BEGIN
  FOR i IN 1 .. len LOOP 
    chunk = input[i];
    IF (chunk = '=') THEN 
      chunk = '=';
    ELSE
      chunk = base32.base32_alphabet(chunk::int);
    END IF;
    output = array_append(output, chunk);
  END LOOP;
  RETURN array_to_string(output, '');
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.encode ( input text ) RETURNS text AS $EOFCODE$
BEGIN
  IF (character_length(input) = 0) THEN 
    RETURN '';
  END IF;

  RETURN
    base32.to_base32(
      base32.to_decimal(
        base32.fill_chunks(
          base32.to_chunks(
            base32.to_groups(
              base32.to_binary(
                base32.to_ascii(
                  input
                )
              )
            )
          )
        )
      )
    );
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.base32_alphabet_to_decimal ( input text ) RETURNS text AS $EOFCODE$
DECLARE
  alphabet text = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  alpha int;
BEGIN
  alpha = position(input in alphabet) - 1;
  IF (alpha < 0) THEN 
    RETURN '=';
  END IF;
  RETURN alpha::text;
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.base32_to_decimal ( input text ) RETURNS text[] AS $EOFCODE$
DECLARE
  i int;
  output text[];
BEGIN
  FOR i IN 1 .. character_length(input) LOOP
    output = array_append(output, base32.base32_alphabet_to_decimal(substring(input from i for 1)));
  END LOOP;
  RETURN output;
END;
$EOFCODE$ LANGUAGE plpgsql STABLE;

CREATE FUNCTION base32.decimal_to_chunks ( input text[] ) RETURNS text[] AS $EOFCODE$
DECLARE
  i int;
  part text;
  output text[];
BEGIN
  FOR i IN 1 .. cardinality(input) LOOP
    part = input[i];
    IF (part = '=') THEN 
      output = array_append(output, 'xxxxx');
    ELSE
      output = array_append(output, right(base32.to_binary(part::int), 5));
    END IF;
  END LOOP;
  RETURN output;
END;
$EOFCODE$ LANGUAGE plpgsql STABLE;

CREATE FUNCTION base32.base32_alphabet_to_decimal_int ( input text ) RETURNS int AS $EOFCODE$
DECLARE
  alphabet text = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  alpha int;
BEGIN
  alpha = position(input in alphabet) - 1;
  RETURN alpha;
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.zero_fill ( a int, b int ) RETURNS bigint AS $EOFCODE$
DECLARE
  bin text;
  m int;
BEGIN

  IF (b >= 32 OR b < -32) THEN 
    m = b/32;
    b = b-(m*32);
  END IF;

  IF (b < 0) THEN
    b = 32 + b;
  END IF;

  IF (b = 0) THEN
      return ((a>>1)&2147483647)*2::bigint+((a>>b)&1);
  END IF;

  IF (a < 0) THEN
    a = (a >> 1); 
    a = a & 2147483647; -- 0x7fffffff
    a = a | 1073741824; -- 0x40000000
    a = (a >> (b - 1)); 
  ELSE
    a = (a >> b); 
  END IF; 

  RETURN a;
END;
$EOFCODE$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION base32.decode ( input text ) RETURNS text AS $EOFCODE$
DECLARE
  i int;
  arr int[];
  output text[];
  len int;
  num int;


  value int = 0;
  index int = 0;
  bits int = 0;
BEGIN
  input = replace(input, '=', '');
  input = upper(input);
  len = character_length(input);
  num = len * 5 / 8;

  IF (len = 0) THEN 
    RETURN '';
  END IF;

  select array(select * from generate_series(1,num))
  INTO arr;
  
  FOR i IN 1 .. len LOOP
    value = (value << 5) | base32.base32_alphabet_to_decimal_int(substring(input from i for 1));
    bits = bits + 5;
    IF (bits >= 8) THEN
      -- arr[index] = (value >>> (bits - 8)) & 255;
      arr[index] = base32.zero_fill(value, (bits - 8)) & 255;
      index = index + 1;
      bits = bits - 8;
    END IF;
  END LOOP;

  -- clean out bad stuff
  -- and then always ends on number equal to the length 
  -- e.g. Cat => [ 67, 97, 116, 3 ] 3 = length (and is in the last position)
  -- e.g. foo =>  [ 102, 111, 111, 3 ] 

  -- TODO WTF??? why does range (0, n-1) work? shouldn't it be 1-n???
  -- Postgres arrays are 1-based by default. And in typical applications it's best to stick with the default. 
  -- ****** But the syntax allows to start with any integer number
  --  WHEN YOU DID THIS ABOVE ^^ arr[index] = base32.zero_fill(value, (bits - 8)) & 255;
  -- YOU LEVERAGED feature of being able to have i = 0

  len = cardinality(arr);
  FOR i IN 0 .. len-2 LOOP
    --  output = array_append(output, i::text);
    --  output = array_append(output, ':[ ');
    --  output = array_append(output, arr[i]::text);
    --  output = array_append(output, '] ');
    --  output = array_append(output, '\n');
     output = array_append(output, chr(arr[i]));
  END LOOP;

  RETURN array_to_string(output, '');
END;
$EOFCODE$ LANGUAGE plpgsql STABLE;