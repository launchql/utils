import { getConnections } from './utils';
import cases from 'jest-in-case';

let db, base32, teardown;
const objs = {
  tables: {}
};

beforeAll(async () => {
  ({ db, teardown } = await getConnections());
  base32 = db.helper('base32');
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

it('tests', () => {
  const bytes = 10;
  const output = [];

  // every bit
  let bits_left = 8;
  let byte_to_write = -1;
  let bit_to_write = 0;
  let bit_to_read = 4;
  let starting_bit = 4;
  let m5 = 0;
  for (let i = 0; i < 8 * bytes; i++) {
    m5 = i % 5;
    if (m5 === 0) {
      byte_to_write = byte_to_write + 1;
      if (i !== 0) {
        starting_bit = starting_bit + 5;
        bit_to_read = starting_bit;
      }
    }
    bit_to_write = 8 * byte_to_write + m5;

    output.push({
      i,
      m5,
      r: bit_to_read,
      w: bit_to_write
    });
    bit_to_read = bit_to_read - 1;
    bits_left = bits_left - 1;
    if (bits_left < 0) bits_left = 8;
  }

  console.log(output);
});

it('string_to_bytea', async () => {
  const [{ string_to_bytea }] = await base32.call('string_to_bytea', {
    input: 'Cat'
  });
  const [{ bytea_to_string }] = await base32.call('bytea_to_string', {
    input: string_to_bytea
  });
  const [{ bytea_to_ascii }] = await base32.call('bytea_to_ascii', {
    input: string_to_bytea
  });
  const [{ to_groups }] = await base32.call(
    'to_groups',
    {
      input: string_to_bytea
    },
    {
      input: 'bytea'
    }
  );
  console.log(to_groups);
  expect(bytea_to_ascii).toEqual([67, 97, 116]);
  expect(bytea_to_string).toEqual('Cat');
});
