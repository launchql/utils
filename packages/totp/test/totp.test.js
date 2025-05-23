import { getConnections, PgTestClient } from 'pgsql-test';

let db: PgTestClient;  // app-level role (with RLS / limited permissions)
let pg: PgTestClient;  // root/superuser for setup/debug
let teardown: () => Promise<void>;

beforeAll(async () => {
  ({ db, pg, teardown } = await getConnections());
});

afterAll(async () => {
  try {
    await teardown();
  } catch (e) {
    // noop - useful for surfacing SQL errors during teardown
  }
});

beforeEach(() => pg.beforeEach());
afterEach(() => pg.afterEach());

it('generates secrets', async () => {
  const result = await pg.one(`SELECT * FROM totp.random_base32($1)`, [16]);
  expect(result).toBeTruthy();
});

it('interval TOTP', async () => {
  const [{ interval }] = await pg.any(
    `SELECT * FROM totp.generate($1) AS interval`,
    ['vmlhl2knm27eftq7']
  );
  expect(interval).toBeTruthy();
});

it('TOTP', async () => {
  const [{ totp }] = await pg.any(
    `SELECT * FROM totp.generate(
      secret := $1, 
      period := $2,
      digits := $3,
      time_from := $4,
      encoding := 'base32'
    ) AS totp`,
    ['vmlhl2knm27eftq7', 30, 6, '2020-02-05 22:11:40.56915+00']
  );
  expect(totp).toEqual('295485');
});

it('validation', async () => {
  const [{ verified }] = await pg.any(
    `SELECT * FROM totp.verify(
      secret := $1,
      check_totp := $2,
      period := $3,
      digits := $4,
      time_from := $5,
      encoding := 'base32'
    ) AS verified`,
    ['vmlhl2knm27eftq7', '295485', 30, 6, '2020-02-05 22:11:40.56915+00']
  );
  expect(verified).toBe(true);
});

it('URL Encode', async () => {
  const [{ urlencode }] = await pg.any(
    `SELECT * FROM totp.urlencode($1)`,
    ['http://hu.wikipedia.org/wiki/São_Paulo']
  );
  expect(urlencode).toEqual('http://hu.wikipedia.org/wiki/S%C3%A3o_Paulo');
});

it('URLs', async () => {
  const [{ url }] = await pg.any(
    `SELECT * FROM totp.url($1, $2, $3, $4) AS url`,
    ['dude@example.com', 'vmlhl2knm27eftq7', 30, 'acme']
  );
  expect(url).toEqual(
    'otpauth://totp/dude@example.com?secret=vmlhl2knm27eftq7&period=30&issuer=acme'
  );
});

it('time-based validation won’t verify in test', async () => {
  const [{ verified }] = await pg.any(
    `SELECT * FROM totp.verify($1, $2, $3, $4) AS verified`,
    ['vmlhl2knm27eftq7', '843386', 30, 6]
  );
  expect(verified).toBe(false);
});
