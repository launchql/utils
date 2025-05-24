# @launchql/totp

<p align="center" width="100%">
  <img height="250" src="https://raw.githubusercontent.com/launchql/launchql/refs/heads/main/assets/outline-logo.svg" />
</p>

<p align="center" width="100%">
  <a href="https://github.com/launchql/utils/actions/workflows/run-tests.yaml">
    <img height="20" src="https://github.com/launchql/utils/actions/workflows/run-tests.yaml/badge.svg" />
  </a>
   <a href="https://github.com/launchql/utils/blob/main/LICENSE"><img height="20" src="https://img.shields.io/badge/license-MIT-blue.svg"/></a>
   <a href="https://www.npmjs.com/package/@launchql/totp"><img height="20" src="https://img.shields.io/github/package-json/v/launchql/utils?filename=packages%2Ftotp%2Fpackage.json"/></a>
</p>

TOTP implementation in pure PostgreSQL plpgsql. This extension provides the HMAC Time-Based One-Time Password Algorithm (TOTP) as specified in RFC 6238 as pure plpgsql functions.

## Usage

### totp.generate

```sql
SELECT totp.generate('mysecret');

-- you can also specify totp_interval, and totp_length
SELECT totp.generate('mysecret', 30, 6);
```

In this case, produces a TOTP code of length 6:

```
013438
```

### totp.verify

```sql
SELECT totp.verify('mysecret', '765430');

-- you can also specify totp_interval, and totp_length
SELECT totp.verify('mysecret', '765430', 30, 6);
```

Depending on input, returns `TRUE/FALSE` 

### totp.url

```sql
-- totp.url ( email text, totp_secret text, totp_interval int, totp_issuer text )
SELECT totp.url(
    'customer@email.com',
    'mysecret',
    30,
    'Acme Inc'
);
```

Will produce a URL-encoded string:

```
otpauth://totp/customer@email.com?secret=mysecret&period=30&issuer=Acme%20Inc
```

## Caveats

Currently only supports `sha1`, pull requests welcome!

## Debugging

Use the verbose option to show keys:

```sh
$ oathtool --totp -v -d 7 -s 10s -b OH3NUPO3WOGOZZQ4
Hex secret: 71f6da3ddbb38cece61c
Base32 secret: OH3NUPO3WOGOZZQ4
Digits: 7
Window size: 0
TOTP mode: SHA1
Step size (seconds): 10
Start time: 1970-01-01 00:00:00 UTC (0)
Current time: 2020-11-18 12:35:08 UTC (1605702908)
Counter: 0x9921BB2 (160570290)
```

Using time for testing:

```sh
oathtool --totp -v -d 6 -s 30s -b vmlhl2knm27eftq7 --now "2020-02-05 22:11:40 UTC"
```

## Credits

Thanks to:
- [RFC 6238 specification](https://tools.ietf.org/html/rfc6238)
- [PGXN OTP distribution](https://pgxn.org/dist/otp/)
- [Improved implementation by bwbroersma](https://gist.github.com/bwbroersma/676d0de32263ed554584ab132434ebd9)

## Related LaunchQL Tooling

### 🧪 Testing

* [launchql/pgsql-test](https://github.com/launchql/launchql/tree/main/packages/pgsql-test): **📊 Isolated testing environments** with per-test transaction rollbacks—ideal for integration tests, complex migrations, and RLS simulation.
* [launchql/graphile-test](https://github.com/launchql/launchql/tree/main/packages/graphile-test): **🔐 Authentication mocking** for Graphile-focused test helpers and emulating row-level security contexts.
* [launchql/pg-query-context](https://github.com/launchql/launchql/tree/main/packages/pg-query-context): **🔒 Session context injection** to add session-local context (e.g., `SET LOCAL`) into queries—ideal for setting `role`, `jwt.claims`, and other session settings.

### 🧠 Parsing & AST

* [launchql/pgsql-parser](https://github.com/launchql/pgsql-parser): **🔄 SQL conversion engine** that interprets and converts PostgreSQL syntax.
* [launchql/libpg-query-node](https://github.com/launchql/libpg-query-node): **🌉 Node.js bindings** for `libpg_query`, converting SQL into parse trees.
* [launchql/pg-proto-parser](https://github.com/launchql/pg-proto-parser): **📦 Protobuf parser** for parsing PostgreSQL Protocol Buffers definitions to generate TypeScript interfaces, utility functions, and JSON mappings for enums.
* [@pgsql/enums](https://github.com/launchql/pgsql-parser/tree/main/packages/enums): **🏷️ TypeScript enums** for PostgreSQL AST for safe and ergonomic parsing logic.
* [@pgsql/types](https://github.com/launchql/pgsql-parser/tree/main/packages/types): **📝 Type definitions** for PostgreSQL AST nodes in TypeScript.
* [@pgsql/utils](https://github.com/launchql/pgsql-parser/tree/main/packages/utils): **🛠️ AST utilities** for constructing and transforming PostgreSQL syntax trees.
* [launchql/pg-ast](https://github.com/launchql/launchql/tree/main/packages/pg-ast): **🔍 Low-level AST tools** and transformations for Postgres query structures.

### 🚀 API & Dev Tools

* [launchql/server](https://github.com/launchql/launchql/tree/main/packages/server): **⚡ Express-based API server** powered by PostGraphile to expose a secure, scalable GraphQL API over your Postgres database.
* [launchql/explorer](https://github.com/launchql/launchql/tree/main/packages/explorer): **🔎 Visual API explorer** with GraphiQL for browsing across all databases and schemas—useful for debugging, documentation, and API prototyping.

### 🔁 Streaming & Uploads

* [launchql/s3-streamer](https://github.com/launchql/launchql/tree/main/packages/s3-streamer): **📤 Direct S3 streaming** for large files with support for metadata injection and content validation.
* [launchql/etag-hash](https://github.com/launchql/launchql/tree/main/packages/etag-hash): **🏷️ S3-compatible ETags** created by streaming and hashing file uploads in chunks.
* [launchql/etag-stream](https://github.com/launchql/launchql/tree/main/packages/etag-stream): **🔄 ETag computation** via Node stream transformer during upload or transfer.
* [launchql/uuid-hash](https://github.com/launchql/launchql/tree/main/packages/uuid-hash): **🆔 Deterministic UUIDs** generated from hashed content, great for deduplication and asset referencing.
* [launchql/uuid-stream](https://github.com/launchql/launchql/tree/main/packages/uuid-stream): **🌊 Streaming UUID generation** based on piped file content—ideal for upload pipelines.
* [launchql/upload-names](https://github.com/launchql/launchql/tree/main/packages/upload-names): **📂 Collision-resistant filenames** utility for structured and unique file names for uploads.

### 🧰 CLI & Codegen

* [@launchql/cli](https://github.com/launchql/launchql/tree/main/packages/cli): **🖥️ Command-line toolkit** for managing LaunchQL projects—supports database scaffolding, migrations, seeding, code generation, and automation.
* [launchql/launchql-gen](https://github.com/launchql/launchql/tree/main/packages/launchql-gen): **✨ Auto-generated GraphQL** mutations and queries dynamically built from introspected schema data.
* [@launchql/query-builder](https://github.com/launchql/launchql/tree/main/packages/query-builder): **🏗️ SQL constructor** providing a robust TypeScript-based query builder for dynamic generation of `SELECT`, `INSERT`, `UPDATE`, `DELETE`, and stored procedure calls—supports advanced SQL features like `JOIN`, `GROUP BY`, and schema-qualified queries.
* [@launchql/query](https://github.com/launchql/launchql/tree/main/packages/query): **🧩 Fluent GraphQL builder** for PostGraphile schemas. ⚡ Schema-aware via introspection, 🧩 composable and ergonomic for building deeply nested queries.

## Disclaimer

AS DESCRIBED IN THE LICENSES, THE SOFTWARE IS PROVIDED "AS IS", AT YOUR OWN RISK, AND WITHOUT WARRANTIES OF ANY KIND.

No developer or entity involved in creating this software will be liable for any claims or damages whatsoever associated with your use, inability to use, or your interaction with other users of the code, including any direct, indirect, incidental, special, exemplary, punitive or consequential damages, or loss of profits, cryptocurrencies, tokens, or anything else of value.

