import { getConnections } from 'pgsql-test';
import { PgTestClient } from 'pgsql-test';

let pg: PgTestClient;
let teardown: () => Promise<void>;

beforeAll(async () => {
  ({ pg, teardown } = await getConnections());
});

afterAll(async () => {
  try {
    await teardown();
  } catch (e) {
    console.log(e);
  }
});

beforeEach(async () => {
  await pg.beforeEach();
});

afterEach(async () => {
  await pg.afterEach();
});

describe('default-roles', () => {
  it('should have the required roles', async () => {
    const result = await pg.query(`
      SELECT rolname
      FROM pg_roles
      WHERE rolname IN ('authenticated', 'anonymous', 'administrator');
    `);
    expect(result.rows.length).toBeGreaterThan(0);
  });
});
