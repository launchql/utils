-- Deploy schemas/totp/procedures/chars2bits to pg

-- requires: schemas/totp/schema

BEGIN;

CREATE FUNCTION totp.chars2bits (_secret text)
  RETURNS text
  AS $code$
DECLARE
    _buffer      text := '';
BEGIN

    with chars2bits AS (
        select
            character,
            (index - 1)::bit(5)::text AS index
        from unnest('{a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,2,3,4,5,6,7}'::text[]) with ordinality as t (character, index)
    )
    select string_agg(c.index, '') INTO _buffer
    from regexp_split_to_table(_secret, '') s
    inner join chars2bits c ON (s = c.character);
    
    return _buffer;

END;
$code$
LANGUAGE 'plpgsql' STABLE;

COMMIT;
