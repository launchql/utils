-- Deploy schemas/status_private/procedures/user_incompleted_step to pg

-- requires: schemas/status_private/schema
-- requires: schemas/status_public/tables/user_steps/table

BEGIN;

CREATE FUNCTION status_private.user_incompleted_step ( 
  step text,
  user_id uuid DEFAULT jwt_public.current_user_id()
) RETURNS void AS $EOFCODE$
  INSERT INTO status_public.user_steps ( step, user_id, count )
  VALUES ( step, user_id, -1 );
$EOFCODE$ LANGUAGE sql VOLATILE SECURITY DEFINER;

COMMIT;
