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

describe('inflection', () => {
  it('should have inflection schema', async () => {
    const result = await db.query(`
      SELECT schema_name
      FROM information_schema.schemata
      WHERE schema_name = 'inflection';
    `);
    expect(result.rows[0]).toBeTruthy();
  });

  it('should pluralize words', async () => {
    const result = await db.query(`SELECT inflection.pluralize('word') as result`);
    expect(result.rows[0].result).toBe('words');
  });

  it('should singularize words', async () => {
    const result = await db.query(`SELECT inflection.singularize('words') as result`);
    expect(result.rows[0].result).toBe('word');
  });

  it('should camelize strings', async () => {
    const result = await db.query(`SELECT inflection.camelize('active_record') as result`);
    expect(result.rows[0].result).toBe('ActiveRecord');
  });

  it('should underscore strings', async () => {
    const result = await db.query(`SELECT inflection.underscore('ActiveRecord') as result`);
    expect(result.rows[0].result).toBe('active_record');
  });
});
