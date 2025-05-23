import { getConnections, PgTestClient } from 'pgsql-test';

let db: PgTestClient;
let pg: PgTestClient;
let teardown: () => Promise<void>;

beforeAll(async () => {
  ({ db, pg, teardown } = await getConnections());

  await db.any(`
    CREATE TABLE public.test_stamps (
      id serial PRIMARY KEY,
      name text,
      created_at timestamptz,
      updated_at timestamptz,
      created_by uuid,
      updated_by uuid
    );

    CREATE TRIGGER set_stamps
    BEFORE INSERT OR UPDATE ON public.test_stamps
    FOR EACH ROW
    EXECUTE FUNCTION stamps.timestamps();

    CREATE TRIGGER set_peoplestamps
    BEFORE INSERT OR UPDATE ON public.test_stamps
    FOR EACH ROW
    EXECUTE FUNCTION stamps.peoplestamps();
  `);
});

afterAll(async () => {
  try {
    await teardown();
  } catch (e) {
    console.error('Teardown failed:', e);
  }
});

beforeEach(() => db.beforeEach());
afterEach(() => db.afterEach());

it('applies timestamps and peoplestamps', async () => {
  // Set JWT context after beforeEach
  await db.setContext({ 'jwt.claims.user_id': '00000000-0000-0000-0000-000000000001' });

  const insertRes = await db.one(
    `INSERT INTO public.test_stamps (name) VALUES ($1) RETURNING *`,
    ['Alice']
  );

  expect(insertRes.created_at).toBeTruthy();
  expect(insertRes.updated_at).toBeTruthy();
  expect(insertRes.created_by).toBe('00000000-0000-0000-0000-000000000001');
  expect(insertRes.updated_by).toBe('00000000-0000-0000-0000-000000000001');
});
