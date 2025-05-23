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

describe('defaults', () => {
  it('should have defaults schema', async () => {
    const [result] = await db.query(`
      SELECT schema_name
      FROM information_schema.schemata
      WHERE schema_name = 'defaults';
    `);
    expect(result).toBeTruthy();
  });
});
