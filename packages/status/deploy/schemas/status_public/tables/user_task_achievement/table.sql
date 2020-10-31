-- Deploy schemas/status_public/tables/user_task_achievement/table to pg

-- requires: schemas/status_public/schema
-- requires: schemas/status_public/tables/user_task/table

BEGIN;

CREATE TABLE status_public.user_task_achievement (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4 (),
  task_id uuid NOT NULL REFERENCES status_public.user_task (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES role_schema.user_table (id) ON DELETE CASCADE
);

COMMIT;
