import { getConnections } from 'pgsql-test';
import { PgTestClient } from 'pgsql-test';
import speakeasy from 'speakeasy';

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

describe('TOTP', () => {
  it('should generate a TOTP secret', async () => {
    const [result] = await db.query(`
      SELECT totp.generate_secret() as secret;
    `);
    expect(result.secret).toBeTruthy();
  });

  it('should verify a TOTP token', async () => {
    const [{ secret }] = await db.query(`
      SELECT totp.generate_secret() as secret;
    `);

    const token = speakeasy.totp({
      secret: secret,
      encoding: 'base32'
    });

    const [result] = await db.query(`
      SELECT totp.verify_token($1, $2) as verified;
    `, [secret, token]);
    
    expect(result.verified).toBe(true);
  });
});
