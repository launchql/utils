-- Deploy schemas/totp/procedures/base32_encode to pg

-- requires: schemas/totp/schema

BEGIN;

CREATE FUNCTION totp.base32_encode(
  input text
)
RETURNS text AS $$
DECLARE
  skip int = 0;
  bits int = 0;
  output text = '';
  x int = 0;
  input_length int = length(input);
  byte int;
  alphabet text = '0123456789abcdefghjkmnpqrtuvwxyz';
BEGIN

  WHILE (x < input_length) LOOP
    -- coerce the byte to an int
    byte := ascii(substring(input from x for 1));

    IF (skip < 0) THEN
      -- we have a carry from the previous byte
      bits := bits | (byte >> (-skip));
    ELSE
      -- no carry
      bits := (byte << skip) & 248;
    END IF;

    IF (skip > 3) THEN
      -- not enough data to produce a character, get us another one
      skip := skip - 8;
      x:= x + 1;
    END IF;

    IF (skip < 4) THEN
      -- produce a character
      output := output || substring(alphabet from (bits >> 3) for 1);
      skip := skip + 5;
    END IF;

  END LOOP;

  IF (skip < 0) THEN
    output := output || substring(alphabet from (bits >> 3) for 1);
  END IF;

  RETURN output;
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

COMMIT;
