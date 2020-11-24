\echo Use "CREATE EXTENSION launchql-ext-status" to load this file. \quit
CREATE SCHEMA status_private;

GRANT USAGE ON SCHEMA status_private TO authenticated, anonymous;

ALTER DEFAULT PRIVILEGES IN SCHEMA status_private 
 GRANT EXECUTE ON FUNCTIONS  TO authenticated;

CREATE SCHEMA status_public;

GRANT USAGE ON SCHEMA status_public TO authenticated, anonymous;

ALTER DEFAULT PRIVILEGES IN SCHEMA status_public 
 GRANT EXECUTE ON FUNCTIONS  TO authenticated;

CREATE TABLE status_public.user_achievement (
 	id uuid PRIMARY KEY DEFAULT ( uuid_generate_v4() ),
	name citext NOT NULL,
	UNIQUE ( name ) 
);

CREATE TABLE status_public.user_task (
 	id uuid PRIMARY KEY DEFAULT ( uuid_generate_v4() ),
	name citext NOT NULL,
	achievement_id uuid NOT NULL REFERENCES status_public.user_achievement ( id ) ON DELETE CASCADE,
	priority int DEFAULT ( 10000 ),
	UNIQUE ( name ) 
);

CREATE TABLE status_public.user_task_achievement (
 	id uuid PRIMARY KEY DEFAULT ( uuid_generate_v4() ),
	task_id uuid NOT NULL REFERENCES status_public.user_task ( id ) ON DELETE CASCADE,
	user_id uuid NOT NULL REFERENCES role_schema.user_table ( id ) ON DELETE CASCADE 
);

CREATE FUNCTION status_private.user_completed_task ( task citext, role_id uuid DEFAULT role_schema.current_role_id() ) RETURNS void AS $EOFCODE$
  INSERT INTO status_public.user_task_achievement (user_id, task_id)
  VALUES (role_id, (
      SELECT
        t.id
      FROM
        status_public.user_task t
      WHERE
        name = task));
$EOFCODE$ LANGUAGE sql VOLATILE SECURITY DEFINER;

CREATE FUNCTION status_private.user_incompleted_task ( task citext, role_id uuid DEFAULT role_schema.current_role_id() ) RETURNS void AS $EOFCODE$
  DELETE FROM status_public.user_task_achievement
  WHERE user_id = role_id
    AND task_id = (
      SELECT
        t.id
      FROM
        status_public.user_task t
      WHERE
        name = task);
$EOFCODE$ LANGUAGE sql VOLATILE SECURITY DEFINER;

CREATE FUNCTION status_public.tasks_required_for ( achievement citext, role_id uuid DEFAULT role_schema.current_role_id() ) RETURNS SETOF status_public.user_task AS $EOFCODE$
BEGIN
  RETURN QUERY
    SELECT
      t.*
    FROM
      status_public.user_task t
    FULL OUTER JOIN status_public.user_task_achievement u ON (
      u.task_id = t.id
      AND u.user_id = role_id
    )
    JOIN status_public.user_achievement f ON (t.achievement_id = f.id)
  WHERE
    u.user_id IS NULL
    AND f.name = achievement
  ORDER BY t.priority ASC
;
END;
$EOFCODE$ LANGUAGE plpgsql STABLE;

CREATE FUNCTION status_public.user_achieved ( achievement citext, role_id uuid DEFAULT role_schema.current_role_id() ) RETURNS boolean AS $EOFCODE$
DECLARE
  v_achievement status_public.user_achievement;
  v_task status_public.user_task;
  v_value boolean = TRUE;
BEGIN
  SELECT * FROM status_public.user_achievement
    WHERE name = achievement
    INTO v_achievement;

  IF (NOT FOUND) THEN
    RETURN FALSE;
  END IF;

  FOR v_task IN
  SELECT * FROM
    status_public.user_task
    WHERE achievement_id = v_achievement.id
  LOOP

    SELECT EXISTS(
      SELECT 1
      FROM status_public.user_task_achievement
      WHERE 
        user_id = role_id
        AND task_id = v_task.id
    ) AND v_value
      INTO v_value;
    
  END LOOP;

  RETURN v_value;

END;
$EOFCODE$ LANGUAGE plpgsql STABLE;

GRANT SELECT ON TABLE status_public.user_achievement TO authenticated;

CREATE INDEX user_id_idx ON status_public.user_task_achievement ( user_id );

ALTER TABLE status_public.user_task_achievement ENABLE ROW LEVEL SECURITY;

CREATE POLICY can_select_user_task_achievement ON status_public.user_task_achievement FOR SELECT TO PUBLIC USING ( role_schema.current_role_id() = user_id );

CREATE POLICY can_insert_user_task_achievement ON status_public.user_task_achievement FOR INSERT TO PUBLIC WITH CHECK ( FALSE );

CREATE POLICY can_update_user_task_achievement ON status_public.user_task_achievement FOR UPDATE TO PUBLIC USING ( FALSE );

CREATE POLICY can_delete_user_task_achievement ON status_public.user_task_achievement FOR DELETE TO PUBLIC USING ( FALSE );

GRANT INSERT ON TABLE status_public.user_task_achievement TO authenticated;

GRANT SELECT ON TABLE status_public.user_task_achievement TO authenticated;

GRANT UPDATE ON TABLE status_public.user_task_achievement TO authenticated;

GRANT DELETE ON TABLE status_public.user_task_achievement TO authenticated;

CREATE FUNCTION status_private.tg_achievement (  ) RETURNS trigger AS $EOFCODE$
DECLARE
  is_null boolean;
  task_name citext;
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        task_name = TG_ARGV[1]::citext;
        EXECUTE format('SELECT ($1).%s IS NULL', TG_ARGV[0])
        USING NEW INTO is_null;
        IF (is_null IS FALSE) THEN
            PERFORM status_private.user_completed_task(task_name);
        END IF;
        RETURN NEW;
    END IF;
END;
$EOFCODE$ LANGUAGE plpgsql VOLATILE;

CREATE FUNCTION status_private.tg_achievement_toggle (  ) RETURNS trigger AS $EOFCODE$
DECLARE
  is_null boolean;
  task_name citext;
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        task_name = TG_ARGV[1]::citext;
        EXECUTE format('SELECT ($1).%s IS NULL', TG_ARGV[0])
        USING NEW INTO is_null;
        IF (is_null IS TRUE) THEN
            PERFORM status_private.user_incompleted_task(task_name);
        ELSE
            PERFORM status_private.user_completed_task(task_name);
        END IF;
        RETURN NEW;
    END IF;
END;
$EOFCODE$ LANGUAGE plpgsql VOLATILE;

CREATE FUNCTION status_private.tg_achievement_boolean (  ) RETURNS trigger AS $EOFCODE$
DECLARE
  is_true boolean;
  task_name citext;
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        task_name = TG_ARGV[1]::citext;
        EXECUTE format('SELECT ($1).%s IS TRUE', TG_ARGV[0])
        USING NEW INTO is_true;
        IF (is_true IS TRUE) THEN
            PERFORM status_private.user_completed_task(task_name);
        END IF;
        RETURN NEW;
    END IF;
END;
$EOFCODE$ LANGUAGE plpgsql VOLATILE;

CREATE FUNCTION status_private.tg_achievement_toggle_boolean (  ) RETURNS trigger AS $EOFCODE$
DECLARE
  is_true boolean;
  task_name citext;
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        task_name = TG_ARGV[1]::citext;
        EXECUTE format('SELECT ($1).%s IS TRUE', TG_ARGV[0])
        USING NEW INTO is_true;
        IF (is_true IS TRUE) THEN
            PERFORM status_private.user_completed_task(task_name);
        ELSE
            PERFORM status_private.user_incompleted_task(task_name);
        END IF;
        RETURN NEW;
    END IF;
END;
$EOFCODE$ LANGUAGE plpgsql VOLATILE;

GRANT SELECT ON TABLE status_public.user_task TO authenticated;