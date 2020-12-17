\echo Use "CREATE EXTENSION launchql-jwt-claims" to load this file. \quit
CREATE SCHEMA jwt_public;

GRANT USAGE ON SCHEMA jwt_public TO authenticated, anonymous;

ALTER DEFAULT PRIVILEGES IN SCHEMA jwt_public 
 GRANT EXECUTE ON FUNCTIONS  TO authenticated;

CREATE SCHEMA jwt_private;

GRANT USAGE ON SCHEMA jwt_private TO authenticated, anonymous;

ALTER DEFAULT PRIVILEGES IN SCHEMA jwt_private 
 GRANT EXECUTE ON FUNCTIONS  TO authenticated;

CREATE FUNCTION jwt_public.current_user_id (  ) RETURNS uuid AS $EOFCODE$
DECLARE
  v_identifier_id uuid;
BEGIN
  IF current_setting('jwt.claims.user_id', TRUE)
    IS NOT NULL THEN
    BEGIN
      v_identifier_id = current_setting('jwt.claims.user_id', TRUE)::uuid;
    EXCEPTION
      WHEN OTHERS THEN
      RAISE NOTICE 'Invalid UUID value';
    RETURN NULL;
    END;
    RETURN v_identifier_id;
  ELSE
    RETURN NULL;
  END IF;
END;
$EOFCODE$ LANGUAGE plpgsql STABLE;