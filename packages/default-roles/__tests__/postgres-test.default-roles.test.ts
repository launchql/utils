import { getConnections } from 'pgsql-test';
import { PgTestClient } from 'pgsql-test';

let pg: PgTestClient;
let db: PgTestClient;
let teardown: () => Promise<void>;

beforeAll(async () => {
  ({ pg, db, teardown } = await getConnections());
});

afterAll(async () => {
  try {
    await teardown();
  } catch (e) {
    console.log(e);
  }
});

beforeEach(async () => {
  await db.beforeEach();
});

afterEach(async () => {
  await db.afterEach();
});

describe('default-roles', () => {
  it('should have the required roles', async () => {
    const result = await db.query(`
      SELECT rolname
      FROM pg_roles
      WHERE rolname IN ('authenticated', 'anonymous', 'administrator');
    `);
    expect(result.rows.length).toBeGreaterThan(0);
  });
});
