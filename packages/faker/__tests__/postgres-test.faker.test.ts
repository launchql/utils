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

describe('faker', () => {
  it('gets random words', async () => {
    const types = [
      'lnglat',
      'address',
      'state',
      'city',
      'file',
      'tags',
      'attachment',
      'birthdate',
      'profilepic'
    ];
    
    for (const t of types) {
      const result = await db.query(`SELECT faker.${t}() as result`);
      expect(result.rows[0].result).toBeTruthy();
    }
  });

  it('lnglat with bbox', async () => {
    const result = await db.query(`
      SELECT faker.lnglat(
        x1 => -118.561721,
        y1 => 33.59,
        x2 => -117.646374,
        y2 => 34.23302
      ) as result
    `);
    expect(result.rows[0].result).toBeTruthy();
  });

  it('tags with parameters', async () => {
    const result = await db.query(`
      SELECT faker.tags(
        min => 5,
        max => 10,
        dict => 'tag'
      ) as result
    `);
    expect(result.rows[0].result).toBeTruthy();
  });

  it('addresses with state', async () => {
    const result = await db.query(`
      SELECT faker.address(
        state => 'CA'
      ) as result
    `);
    expect(result.rows[0].result).toBeTruthy();
  });

  it('addresses with city and state', async () => {
    const result = await db.query(`
      SELECT faker.address(
        state => 'CA',
        city => 'Los Angeles'
      ) as result
    `);
    expect(result.rows[0].result).toBeTruthy();
  });
});
