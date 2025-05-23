import { getConnections } from 'pgsql-test';
import { PgTestClient } from 'pgsql-test';
import cases from 'jest-in-case';

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

describe('Base32 Encoding', () => {
  it('to_ascii', async () => {
    const [{ to_ascii }] = await db.query(`
      SELECT base32.to_ascii('Cat') as to_ascii;
    `);
    expect(to_ascii).toEqual([67, 97, 116]);
  });

  it('to_binary', async () => {
    const [{ to_binary }] = await db.query(`
      SELECT base32.to_binary(ARRAY[67, 97, 116]) as to_binary;
    `);
    expect(to_binary).toEqual(['01000011', '01100001', '01110100']);
  });

  it('to_groups', async () => {
    const [{ to_groups }] = await db.query(`
      SELECT base32.to_groups(ARRAY['01000011', '01100001', '01110100']) as to_groups;
    `);
    expect(to_groups).toEqual([
      '01000011',
      '01100001',
      '01110100',
      'xxxxxxxx',
      'xxxxxxxx'
    ]);
  });

  it('to_chunks', async () => {
    const [{ to_chunks }] = await db.query(`
      SELECT base32.to_chunks(ARRAY['01000011', '01100001', '01110100', 'xxxxxxxx', 'xxxxxxxx']) as to_chunks;
    `);
    expect(to_chunks).toEqual([
      '01000',
      '01101',
      '10000',
      '10111',
      '0100x',
      'xxxxx',
      'xxxxx',
      'xxxxx'
    ]);
  });

  it('fill_chunks', async () => {
    const [{ fill_chunks }] = await db.query(`
      SELECT base32.fill_chunks(ARRAY[
        '01000',
        '01101',
        '10000',
        '10111',
        '0100x',
        'xxxxx',
        'xxxxx',
        'xxxxx'
      ]) as fill_chunks;
    `);
    expect(fill_chunks).toEqual([
      '01000',
      '01101',
      '10000',
      '10111',
      '01000',
      'xxxxx',
      'xxxxx',
      'xxxxx'
    ]);
  });

  it('to_decimal', async () => {
    const [{ to_decimal }] = await db.query(`
      SELECT base32.to_decimal(ARRAY[
        '01000',
        '01101',
        '10000',
        '10111',
        '01000',
        'xxxxx',
        'xxxxx',
        'xxxxx'
      ]) as to_decimal;
    `);
    expect(to_decimal).toEqual(['8', '13', '16', '23', '8', '=', '=', '=']);
  });

  it('to_base32', async () => {
    const [{ to_base32 }] = await db.query(`
      SELECT base32.to_base32(ARRAY['8', '13', '16', '23', '8', '=', '=', '=']) as to_base32;
    `);
    expect(to_base32).toEqual('INQXI===');
  });

  cases(
    'base32',
    async (opts) => {
      const [result] = await db.query(`
        SELECT base32.encode('${opts.name}') as encode;
      `);
      expect(result.encode).toEqual(opts.result);
    },
    [
      { name: '', result: '' },
      { name: 'f', result: 'MY======' },
      { name: 'fo', result: 'MZXQ====' },
      { name: 'foo', result: 'MZXW6===' },
      { name: 'foob', result: 'MZXW6YQ=' },
      { name: 'fooba', result: 'MZXW6YTB' },
      { name: 'foobar', result: 'MZXW6YTBOI======' }
    ]
  );
});
