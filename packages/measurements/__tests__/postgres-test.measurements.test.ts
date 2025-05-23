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

describe('measurements', () => {
  it('should have measurements schema', async () => {
    const result = await db.query(`
      SELECT schema_name
      FROM information_schema.schemata
      WHERE schema_name = 'measurements';
    `);
    expect(result.rows[0]).toBeTruthy();
  });

  it('should have quantities table', async () => {
    const result = await db.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'measurements' AND table_name = 'quantities';
    `);
    expect(result.rows[0]).toBeTruthy();
  });
});
