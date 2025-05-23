import { getConnections, PgTestClient } from 'pgsql-test';

jest.setTimeout(15000);

const validUrls = [
  'http://foo.com/blah_blah',
  'http://foo.com/blah_blah/',
  'http://foo.com/blah_blah_(wikipedia)',
  'http://foo.com/blah_blah_(wikipedia)_(again)',
  'http://www.example.com/wpstyle/?p=364',
  'https://www.example.com/foo/?bar=baz&inga=42&quux',
  'http://✪df.ws/123',
  'http://foo.com/blah_(wikipedia)#cite-1',
  'http://foo.com/blah_(wikipedia)_blah#cite-1',
  'http://foo.com/(something)?after=parens',
  'http://code.google.com/events/#&product=browser',
  'http://j.mp',
  'http://foo.bar/?q=Test%20URL-encoded%20stuff',
  'http://مثال.إختبار',
  'http://例子.测试',
  'http://उदाहरण.परीक्षा',
  "http://-.~_!$&'()*+,;=:%40:80%2f::::::@example.com",
  'http://1337.net',
  'http://a.b-c.de',
  'https://foo_bar.example.com/'
];

const invalidUrls = [
  'http://##',
  'http://##/',
  'http://foo.bar?q=Spaces should be encoded',
  '//',
  '//a',
  '///a',
  '///',
  'http:///a',
  'foo.com',
  'rdar://1234',
  'h://test',
  'http:// shouldfail.com',
  ':// should fail',
  'http://foo.bar/foo(bar)baz quux',
  'ftps://foo.bar/',
  'http://.www.foo.bar/',
  'http://.www.foo.bar./'
];

const validAttachments = [
  { url: 'http://www.foo.bar/some.jpg', mime: 'image/jpg' },
  { url: 'https://foo.bar/some.PNG', mime: 'image/jpg' }
];

const invalidAttachments = [
  { url: 'hi there' },
  { url: 'https://foo.bar/some.png' }
];

let db: PgTestClient;
let pg: PgTestClient;
let teardown: () => Promise<void>;

beforeAll(async () => {
  ({ db, pg, teardown } = await getConnections());

  await pg.any(`
    CREATE TABLE customers (
      id serial,
      url url,
      image image,
      attachment attachment,
      domain hostname,
      email email
    );
  `);
});

afterAll(async () => {
  try {
    await teardown();
  } catch (e) {
    // ignore teardown errors for visibility
  }
});

describe('types', () => {
  it('valid attachment and image', async () => {
    for (const value of validAttachments) {
      try {
        await pg.query(`INSERT INTO customers (image) VALUES ($1::json);`, [value]);
      } catch (err) {
        console.error('Failed inserting into `image` column:', {
          value,
          // @ts-ignore
          error: err.message,
        });
        // @ts-ignore
        throw new Error(`Failed to insert image JSON value: ${JSON.stringify(value)}\n${err.message}`);
      }
      
      try {
        await pg.query(`INSERT INTO customers (attachment) VALUES ($1);`, [value.url]);
      } catch (err) {
        console.error('Failed inserting into `attachment` column:', {
          value,
          // @ts-ignore
          error: err.message,
        });
        // @ts-ignore
        throw new Error(`Failed to insert attachment JSON value: ${JSON.stringify(value)}\n${err.message}`);
      }
    }
  });
  
  it('invalid attachment and image', async () => {
    for (const value of invalidAttachments) {
      let failed = false;
      try {
        await pg.any(`INSERT INTO customers (attachment) VALUES ($1);`, [value]);
      } catch {
        failed = true;
      }
      expect(failed).toBe(true);

      failed = false;
      try {
        await pg.any(`INSERT INTO customers (image) VALUES ($1);`, [value]);
      } catch {
        failed = true;
      }
      expect(failed).toBe(true);
    }
  });

  it('valid url', async () => {
    for (const value of validUrls) {
      await pg.any(`INSERT INTO customers (url) VALUES ($1);`, [value]);
    }
  });

  it('invalid url', async () => {
    for (const value of invalidUrls) {
      let failed = false;
      try {
        await pg.any(`INSERT INTO customers (url) VALUES ($1);`, [value]);
      } catch {
        failed = true;
      }
      expect(failed).toBe(true);
    }
  });

  it('email', async () => {
    await pg.any(`
      INSERT INTO customers (email) VALUES
        ('d@google.com'),
        ('d@google.in'),
        ('d@google.in'),
        ('d@www.google.in'),
        ('d@google.io'),
        ('dan@google.some.other.com');
    `);
  });

  it('not email', async () => {
    let failed = false;
    try {
      await pg.any(`INSERT INTO customers (email) VALUES ('http://google.some.other.com');`);
    } catch {
      failed = true;
    }
    expect(failed).toBe(true);
  });

  it('hostname', async () => {
    await pg.any(`
      INSERT INTO customers (domain) VALUES
        ('google.com'),
        ('google.in'),
        ('google.in'),
        ('www.google.in'),
        ('google.io'),
        ('google.some.other.com');
    `);
  });

  it('not hostname', async () => {
    let failed = false;
    try {
      await pg.any(`INSERT INTO customers (domain) VALUES ('http://google.some.other.com');`);
    } catch {
      failed = true;
    }
    expect(failed).toBe(true);
  });

  it('not hostname 2', async () => {
    let failed = false;
    try {
      await pg.any(`INSERT INTO customers (domain) VALUES ('google.some.other.com/a/b/d');`);
    } catch {
      failed = true;
    }
    expect(failed).toBe(true);
  });
});
