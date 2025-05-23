import { getConnections } from 'pgsql-test';
import { PgTestClient } from 'pgsql-test';

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
  {
    url: 'http://www.foo.bar/some.jpg',
    mime: 'image/jpg'
  },
  {
    url: 'https://foo.bar/some.PNG',
    mime: 'image/jpg'
  }
];

const invalidAttachments = [
  {
    url: 'hi there'
  },
  {
    url: 'https://foo.bar/some.png'
  }
];

let pg: PgTestClient;
let db: PgTestClient;
let teardown: () => Promise<void>;

beforeAll(async () => {
  ({ pg, db, teardown } = await getConnections());
});

beforeAll(async () => {
  await db.query(`
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
    console.log(e);
  }
});

beforeEach(async () => {
  await db.beforeEach();
});

afterEach(async () => {
  await db.afterEach();
});

describe('types', () => {
  it('valid attachment and image', async () => {
    for (let i = 0; i < validAttachments.length; i++) {
      const value = validAttachments[i];
      await db.query(`INSERT INTO customers (image) VALUES ($1::json);`, [value]);
      await db.query(`INSERT INTO customers (attachment) VALUES ($1::json);`, [
        value
      ]);
    }
  });

  it('invalid attachment and image', async () => {
    for (let i = 0; i < invalidAttachments.length; i++) {
      const value = invalidAttachments[i];
      let failed = false;
      try {
        await db.query(`INSERT INTO customers (attachment) VALUES ($1);`, [
          value
        ]);
      } catch (e) {
        failed = true;
      }
      expect(failed).toBe(true);
      failed = false;
      try {
        await db.query(`INSERT INTO customers (image) VALUES ($1);`, [value]);
      } catch (e) {
        failed = true;
      }
      expect(failed).toBe(true);
    }
  });

  it('valid url', async () => {
    for (let i = 0; i < validUrls.length; i++) {
      const value = validUrls[i];
      await db.query(`INSERT INTO customers (url) VALUES ($1);`, [value]);
    }
  });

  it('invalid url', async () => {
    for (let i = 0; i < invalidUrls.length; i++) {
      const value = invalidUrls[i];
      let failed = false;
      try {
        await db.query(`INSERT INTO customers (url) VALUES ($1);`, [value]);
      } catch (e) {
        failed = true;
      }
      expect(failed).toBe(true);
    }
  });

  it('email', async () => {
    await db.query(`
    INSERT INTO customers (email) VALUES
    ('d@google.com'),
    ('d@google.in'),
    ('d@google.in'),
    ('d@www.google.in'),
    ('d@google.io'),
    ('dan@google.some.other.com')`);
  });

  it('not email', async () => {
    let failed = false;
    try {
      await db.query(`
      INSERT INTO customers (email) VALUES
      ('http://google.some.other.com')`);
    } catch (e) {
      failed = true;
    }
    expect(failed).toBe(true);
  });

  it('hostname', async () => {
    await db.query(`
    INSERT INTO customers (domain) VALUES
    ('google.com'),
    ('google.in'),
    ('google.in'),
    ('www.google.in'),
    ('google.io'),
    ('google.some.other.com')`);
  });

  it('not hostname', async () => {
    let failed = false;
    try {
      await db.query(`
      INSERT INTO customers (domain) VALUES
      ('http://google.some.other.com')`);
    } catch (e) {
      failed = true;
    }
    expect(failed).toBe(true);
  });

  it('not hostname 2', async () => {
    let failed = false;
    try {
      await db.query(`
      INSERT INTO customers (domain) VALUES
      ('google.some.other.com/a/b/d')`);
    } catch (e) {
      failed = true;
    }
    expect(failed).toBe(true);
  });
});
