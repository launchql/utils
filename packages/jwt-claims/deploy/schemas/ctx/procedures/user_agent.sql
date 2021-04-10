-- Deploy schemas/ctx/procedures/user_agent to pg

-- requires: schemas/ctx/schema

BEGIN;

CREATE FUNCTION ctx.user_agent()
  RETURNS text
AS $$
  SELECT current_setting('jwt.claims.user_agent', true);
$$
LANGUAGE 'sql' STABLE;

COMMIT;