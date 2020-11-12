-- Deploy schemas/totp/procedures/base32_decode to pg

-- requires: schemas/totp/schema

BEGIN;


CREATE OR REPLACE FUNCTION totp.base32_decode(
  input text
)
RETURNS text AS $$
DECLARE
  skip int = 0;
  bits int = 0;
  output text = '';
  val int;
  byte int;
  x int = 0;
  input_length int = length(input);
  ch text;
  lookup json;
  alphabet text = '0123456789abcdefghjkmnpqrtuvwxyz';
BEGIN
  lookup := json_build_object(
    '0', 0,
    '1', 1,
    '2', 2,
    '3', 3,
    '4', 4,
    '5', 5,
    '6', 6,
    '7', 7,
    '8', 8,
    '9', 9,
    'a', 10,
    'b', 11,
    'c', 12,
    'd', 13,
    'e', 14,
    'f', 15,
    'g', 16,
    'h', 17,
    'j', 18,
    'k', 19,
    'm', 20,
    'n', 21,
    'p', 22,
    'q', 23,
    'r', 24,
    't', 25,
    'u', 26,
    'v', 27,
    'w', 28,
    'x', 29,
    'y', 30,
    'z', 31,
    'o', 0,
    'i', 1,
    'l', 1,
    's', 5
  );

FOR x IN 0 .. input_length LOOP
    ch := lower(substring(input from x for 1));

    val := lookup::json->>ch;
    IF (val IS NULL) THEN
      CONTINUE;
      --TODO this could be an issue
      --RAISE EXCEPTION '% was not found!', ch;
    END IF;

    val := val << 3;

    -- byte := byte | (val >>> skip);
    byte := byte | (val >> skip);

    skip := skip + 5;

    IF (skip >= 8) THEN
      -- we have enough to produce output
      output := concat(output, chr(byte));
      skip := skip - 8;
      IF (skip > 0) THEN
        byte := (val << (5 - skip)) & 255;
      ELSE
        byte = 0;
      END IF;
    END IF;

  END LOOP;
   
  IF (skip < 0) THEN
      output := concat(output, substring(alphabet from (bits >> 3) for 1));
  END IF;

  RETURN output;
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

COMMIT;
