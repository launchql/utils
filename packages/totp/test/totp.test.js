import { getConnections } from './utils';
// import speakeasy from 'speakeasy';
// import { totp as gentotp } from './utils/util';
import { otp } from './utils/attempt2';

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

describe('TOTP', () => {
  describe('generate TOTP', () => {
    it('generates secrets', async () => {
      const _secret = await db.one(
        `
        SELECT * FROM totp.random_base32($1)
      `,
        [16]
      );
      console.log('generates secrets', _secret);
      expect(_secret).toBeTruthy();
    });
    it('interval TOTP', async () => {
      const [{ interval }] = await db.any(
        `
        SELECT * FROM totp.generate_totp($1) as interval
        `,
        ['vmlhl2knm27eftq7']
      );
      // console.log('interval TOTP', interval);
      expect(interval).toBeTruthy();
    });
    it('timekey', async () => {
      const [{ key }] = await db.any(
        `
          SELECT * FROM totp.generate_totp_time_key($1, $2) as key
          `,
        [30, '2020-02-05 22:11:40.56915+00']
      );
      // console.log(key, 'timekey');
      expect(key).toEqual('0000000003241ba7');
    });
    it('TOTP', async () => {
      const [{ totp }] = await db.any(
        `
        SELECT * FROM totp.generate_totp($1, $2, $3, $4) as totp
      `,
        ['vmlhl2knm27eftq7', 30, 6, '2020-02-05 22:11:40.56915+00']
      );

      // console.log({ totp });
      // console.log({ totp });

      // const result = gentotp({ secret: '12345678901234567890', time: 59 });
      // console.log({ result });
      // console.log({ result });

      // console.log(speakeasy.digest());
      // expect(totp).toEqual('843386');
      expect(totp).toEqual('367269');
    });
    it('TOTP', async () => {
      // const [results] = await totp.call('byte_secret', {
      //   secret: '12345678901234567890'
      // });
      const [results] = await db.any(
        `
        SELECT * FROM totp.gtotp($1, $2) as totp
      `,
        ['12345678901234567890', 59]
      );

      // console.log({ results });
      // console.log({ results });

      const result = otp('JBSWY3DPEHPK3PXP');
      console.log(result);
      console.log(result);
    });
    it('validation', async () => {
      const [{ verified }] = await db.any(
        `
        SELECT * FROM totp.verify_totp($1, $2, $3, $4, $5) as verified
      `,
        ['vmlhl2knm27eftq7', 30, 6, '367269', '2020-02-05 22:11:40.56915+00']
        // ['vmlhl2knm27eftq7', 30, 6, '843386', '2020-02-05 22:11:40.56915+00']
      );
      expect(verified).toBe(true);
    });
    it('URL Encode', async () => {
      const [{ urlencode }] = await db.any(
        `
        SELECT * FROM totp.urlencode($1)
      `,
        ['http://hu.wikipedia.org/wiki/São_Paulo']
      );
      expect(urlencode).toEqual('http://hu.wikipedia.org/wiki/S%C3%A3o_Paulo');
    });
    it('URLs', async () => {
      const [{ url }] = await db.any(
        `
        SELECT * FROM totp.totp_url($1, $2, $3, $4) as url
      `,
        ['dude@example.com', 'vmlhl2knm27eftq7', 30, 'acme']
      );
      expect(url).toEqual(
        'otpauth://totp/dude@example.com?secret=vmlhl2knm27eftq7&period=30&issuer=acme'
      );
    });
    it('time-based validation wont verify in test', async () => {
      const [{ verified }] = await db.any(
        `
        SELECT * FROM totp.verify_totp($1, $2, $3, $4, $5) as verified
      `,
        ['vmlhl2knm27eftq7', 30, 6, '843386', null]
      );
      expect(verified).toBe(false);
    });
  });
});
