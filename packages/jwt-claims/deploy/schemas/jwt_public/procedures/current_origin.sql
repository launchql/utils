-- Deploy schemas/jwt_public/procedures/current_origin to pg

-- requires: schemas/jwt_public/schema

BEGIN;

CREATE FUNCTION jwt_public.current_origin()
  RETURNS origin
AS $$
DECLARE
  v_origin origin;
BEGIN
  IF current_setting('jwt.claims.origin', TRUE)
    IS NOT NULL THEN
    BEGIN
      v_origin = trim(current_setting('jwt.claims.origin', TRUE))::origin;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE NOTICE 'Invalid Origin';
    RETURN NULL;
    END;
    RETURN v_origin;
  ELSE
    RETURN NULL;
  END IF;
END;
$$
LANGUAGE 'plpgsql' STABLE;

COMMIT;
