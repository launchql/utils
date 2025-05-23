import { getConnections, PgTestClient } from 'pgsql-test';

let db: PgTestClient;
let pg: PgTestClient;
let teardown: () => Promise<void>;

const objs = {
  tables: {}
};

beforeAll(async () => {
  ({ db, pg, teardown } = await getConnections());
});

afterAll(async () => {
  try {
    // try catch here allows us to see the SQL parsing issues!
    await teardown();
  } catch (e) {
    // noop
  }
});

beforeEach(() => pg.beforeEach());
afterEach(() => pg.afterEach());

it('gets random words', async () => {
  const obj: Record<string, any> = {};
  const types = [
    // 'word',
    // 'sentence',
    // 'paragraph',
    // 'email',
    // 'integer',
    // 'float',
    // 'timestamptz',
    // 'date',
    // 'interval',
    // 'image',
    // 'image_mime',
    // 'mime',
    // 'uuid',
    // 'token',
    // 'password',
    // 'hostname',
    // 'upload',
    // 'username',
    // 'gender',
    // 'name',
    // 'surname',
    // 'fullname',
    // 'phone',
    // 'street',
    'lnglat',
    'address',
    'state',
    'city',
    'file',
    'tags',
    'attachment',
    'birthdate',
    'profilepic'
    // 'ext',
    // 'ip',
    // 'business'
  ];

  for (const type of types) {
    const { [type]: value } = await pg.one(`SELECT faker.${type}() AS ${type}`);
    obj[type] = value;
  }
  console.log(obj);
});

it('lnglat', async () => {
  const obj: Record<string, any> = {};
  const { lnglat } = await pg.one(`SELECT faker.lnglat() AS lnglat`);
  obj['lnglat'] = lnglat;

  const { lnglat: bbox } = await pg.one(
    `SELECT faker.lnglat($1, $2, $3, $4) AS lnglat`,
    [-118.561721, 33.59, -117.646374, 34.23302]
  );
  obj['bbox'] = bbox;

  console.log(obj);
  console.log(obj.bbox.y, ',', obj.bbox.x);
});

it('tags', async () => {
  const obj: Record<string, any> = {};

  const { tags } = await pg.one(`SELECT faker.tags() AS tags`);
  obj['tags'] = tags;

  const { tag_with_min } = await pg.one(
    `SELECT faker.tags($1, $2, $3) AS tag_with_min`,
    [5, 10, 'tag']
  );
  obj['tag with min'] = tag_with_min;

  const { face } = await pg.one(
    `SELECT faker.tags($1, $2, $3) AS face`,
    [5, 10, 'face']
  );
  obj['face'] = face;

  console.log(obj);
});

it('addresses', async () => {
  const obj: Record<string, any> = {};

  obj['any'] = (await pg.one(`SELECT faker.address() AS value`)).value;
  obj['CA'] = (await pg.one(`SELECT faker.address($1) AS value`, ['CA'])).value;
  obj['MI'] = (await pg.one(`SELECT faker.address($1) AS value`, ['MI'])).value;
  obj['Los Angeles'] = (
    await pg.one(`SELECT faker.address($1, $2) AS value`, ['CA', 'Los Angeles'])
  ).value;

  console.log(obj);
});

// Placeholder for future word + cat-based generation tests
xit('mixed words and args', async () => {
  const obj: Record<string, any> = {};

  obj['english-words'] = (
    await pg.one(
      `SELECT faker.sentence($1, $2, $3, $4) AS value`,
      ['word', 7, 20, ['colors']]
    )
  ).value;

  obj['mixed-words'] = (
    await pg.one(
      `SELECT faker.sentence($1, $2, $3, $4) AS value`,
      ['word', 7, 20, ['colors', 'adjectives', 'surname', 'animals', 'stop']]
    )
  ).value;

  obj['sentence-words'] = (
    await pg.one(
      `SELECT faker.sentence($1, $2, $3, $4) AS value`,
      ['word', 7, 20, ['lorem']]
    )
  ).value;

  obj['sentence-chars'] = (
    await pg.one(
      `SELECT faker.sentence($1, $2, $3, $4) AS value`,
      ['char', 100, 140, ['lorem']]
    )
  ).value;

  obj['paragraph-chars'] = (
    await pg.one(
      `SELECT faker.paragraph($1, $2, $3, $4) AS value`,
      ['char', 300, 500, ['lorem']]
    )
  ).value;

  obj['integer-chars'] = (
    await pg.one(`SELECT faker.integer($1, $2) AS value`, [300, 500])
  ).value;

  obj['xenial'] = (
    await pg.one(`SELECT faker.birthdate($1, $2) AS value`, [34, 39])
  ).value;

  console.log(obj);
});

// Placeholder for business tests
// it('businesses', async () => {
//   for (let i = 0; i < 20; i++) {
//     const { business } = await pg.one(`SELECT faker.business() AS business`);
//     console.log(business);
//   }
// });

// Placeholder for city/zip tests
// it('cities', async () => {
//   for (let i = 0; i < 20; i++) {
//     const { city } = await pg.one(`SELECT faker.city() AS city`);
//     console.log(city);

//     const { city: city2 } = await pg.one(`SELECT faker.city($1) AS city`, ['MI']);
//     console.log(city2);

//     const { zip } = await pg.one(`SELECT faker.zip() AS zip`);
//     console.log(zip);

//     const { zip: zip2 } = await pg.one(`SELECT faker.zip($1) AS zip`, ['Los Angeles']);
//     console.log(zip2);
//   }
// });
