-- Deploy schemas/ctx/procedures/security_definer to pg

-- requires: schemas/ctx/schema

BEGIN;

DO $LQLMIGRATION$
  DECLARE
  BEGIN
    EXECUTE format('CREATE FUNCTION ctx.security_definer() returns text as $$
      SELECT ''%s'';
$$
LANGUAGE ''sql'' STABLE;', current_user);
    EXECUTE format('CREATE FUNCTION ctx.is_security_definer() returns bool as $$
      SELECT ''%s'' = current_user;
$$
LANGUAGE ''sql'' STABLE;', current_user);
  END;
$LQLMIGRATION$;
GRANT EXECUTE ON FUNCTION ctx.security_definer() TO PUBLIC;
GRANT EXECUTE ON FUNCTION ctx.is_security_definer() TO PUBLIC;

COMMIT;
