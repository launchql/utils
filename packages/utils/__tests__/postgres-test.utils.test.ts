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

it('more', async () => {
  const [result] = await db.query(`
    SELECT utils.mask_pad('101', 20) as result;
  `);
  expect(result).toBeTruthy();
});

it('less', async () => {
  const [result] = await db.query(`
    SELECT utils.mask_pad('101', 2) as result;
  `);
  expect(result).toBeTruthy();
});

describe('bitmask', () => {
  it('more', async () => {
    const [result] = await db.query(`
      SELECT utils.bitmask_pad('101', 20) as result;
    `);
    expect(result).toBeTruthy();
  });

  it('less', async () => {
    const [result] = await db.query(`
      SELECT utils.bitmask_pad('101', 2) as result;
    `);
    expect(result).toBeTruthy();
  });
});
