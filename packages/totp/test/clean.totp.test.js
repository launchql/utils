import { getConnections } from './utils';

let db, totp, teardown;
const objs = {
  tables: {}
};

beforeAll(async () => {
  ({ db, teardown } = await getConnections());
  totp = db.helper('totp');
});

afterAll(async () => {
  try {
    //try catch here allows us to see the sql parsing issues!
    await teardown();
  } catch (e) {
    // noop
  }
});

beforeEach(async () => {
  await db.beforeEach();
});

afterEach(async () => {
  await db.afterEach();
});

// https://www.youtube.com/watch?v=VOYxF12K1vE
const time = '2018-12-4 20:24:20+08:00';
const steps = 30;
it('T_unix', async () => {
  const { t_unix } = await db.one(
    `
    SELECT totp.t_unix($1::timestamptz)
      `,
    [time]
  );
  expect(t_unix).toEqual(1543926260);
});

it('N', async () => {
  // N = number of steps which have elapsed since Unix Epoch time
  const { n } = await db.one(
    `
    SELECT 
            totp.n(
                $1,
                $2
            ) 
      `,
    [time, steps]
  );
  expect(n).toEqual(51464208);
});

it('N_hex', async () => {
  const { n_hex } = await db.one(
    `
    SELECT 
            totp.n_hex($1)
      `,
    [51464208]
  );
  expect(n_hex).toEqual('0000000003114810');
});

it('N_hex tp 8 byte array', async () => {
  // 0000000003114810
  // 00 00 00 00 03 11 48 10
  // https://youtu.be/VOYxF12K1vE?t=460

  const result = await db.one(
    `
    SELECT 
            totp.n_hex_to_8_bytes( totp.n_hex($1) )
      `,
    [51464208]
  );
  console.log(result);
});

it('convert base32 secret into 20 bytes', async () => {
  // JBSWY3DPEHPK3PXP
  // l43y22ygno65xbrdhoxd
  // randomly generated 20 bytes number which is base32 encoded
  //   https://youtu.be/VOYxF12K1vE?t=477
  const result = await db.one(
    `
    SELECT 
            totp.random_base32( 20 )
      `
  );
  console.log(result);
});

it('hmac', async () => {
  // JBSWY3DPEHPK3PXP
  // l43y22ygno65xbrdhoxd
  // randomly generated 20 bytes number which is base32 encoded
  //   https://youtu.be/VOYxF12K1vE?t=477

  const { hmac_as_20_bytes } = await db.one(
    `
    SELECT 
            totp.hmac_as_20_bytes( 
                totp.n_hex_to_8_bytes( totp.n_hex($1) ),
                $2
             )::text
      `,
    [51464208, 'l43y22ygno65xbrdhoxd']
  );
  expect(hmac_as_20_bytes).toEqual(
    '\\x1b48af986fb847a714cd647a5b44254433f55c8d'
  );
});

it('hmac offset', async () => {
  const { get_offset } = await db.one(
    `
    SELECT  totp.get_offset(
            totp.hmac_as_20_bytes( 
                totp.n_hex_to_8_bytes( totp.n_hex($1) ),
                $2
             ))
      `,
    [51464208, 'l43y22ygno65xbrdhoxd']
  );
  expect(get_offset).toEqual(13);
});

it('hmac offset', async () => {
  const { get_offset } = await db.one(
    `
    SELECT  totp.get_offset(
        '\\xaf16868fe5db00c15875f6a7f899f528ab805e9a'::bytea    
        )
      `
  );
  expect(get_offset).toEqual(10);
});

it('first 4 bytes from hmac starting at offset', async () => {
  const { get_first_4_bytes_from_offset } = await db.one(
    `
    SELECT  totp.get_first_4_bytes_from_offset(
        '\\xaf16868fe5db00c15875f6a7f899f528ab805e9a'::bytea,
        10  
        )
      `
  );
  expect(get_first_4_bytes_from_offset).toEqual([246, 167, 248, 153]);
});

it('apply_binary_to_bytes', async () => {
  // https://youtu.be/VOYxF12K1vE?t=554
  const { apply_binary_to_bytes } = await db.one(
    `
    SELECT  totp.apply_binary_to_bytes(
        $1::int[]  
        )
      `,
    [[246, 167, 248, 153]]
  );
  console.log(apply_binary_to_bytes);
  expect(apply_binary_to_bytes).toEqual([118, 167, 248, 153]);
  expect(apply_binary_to_bytes).toEqual([0x76, 0xa7, 0xf8, 0x99]);
  // 0x76a7f899
});

it('compact_bytes_to_int', async () => {
  // https://youtu.be/VOYxF12K1vE?t=554
  const { compact_bytes_to_int } = await db.one(
    `
    SELECT  totp.compact_bytes_to_int(
        $1::int[]  
        )
      `,
    [[118, 167, 248, 153]]
  );
  expect(compact_bytes_to_int).toEqual(1990719641);
});

it('calculate_token', async () => {
  const { calculate_token } = await db.one(
    `
    SELECT  totp.calculate_token(
        $1::int,
        6
        )
      `,
    [1990719641]
  );
  expect(calculate_token).toEqual('719641');
});

it('calculate_token', async () => {
  const { calculate_token } = await db.one(
    `
    SELECT  totp.calculate_token(
        $1::int,
        4
        )
      `,
    [1990719641]
  );
  expect(calculate_token).toEqual('9641');
});
