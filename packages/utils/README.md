# @launchql/utils

<p align="center" width="100%">
  <img height="250" src="https://raw.githubusercontent.com/launchql/launchql/refs/heads/main/assets/outline-logo.svg" />
</p>

<p align="center" width="100%">
  <a href="https://github.com/launchql/utils/actions/workflows/run-tests.yaml">
    <img height="20" src="https://github.com/launchql/utils/actions/workflows/run-tests.yaml/badge.svg" />
  </a>
   <a href="https://github.com/launchql/utils/blob/main/LICENSE"><img height="20" src="https://img.shields.io/badge/license-MIT-blue.svg"/></a>
   <a href="https://www.npmjs.com/package/@launchql/utils"><img height="20" src="https://img.shields.io/github/package-json/v/launchql/utils?filename=packages%2Futils%2Fpackage.json"/></a>
</p>

A lightweight PostgreSQL utility extension providing helper functions for bitmask padding and custom trigger-based exceptions. Useful for schema consistency and low-level logic utilities in advanced database projects.

## Features

* 🏗️ **Schema creation**: Automatically sets up a `utils` schema with sensible defaults.
* 🧮 **Bitmask manipulation**:

  * `utils.mask_pad`: Pads or trims a text-based bit string.
  * `utils.bitmask_pad`: Same logic, but for PostgreSQL `VARBIT` types.
* ⚠️ **Trigger error handler**:

  * `utils.throw`: A customizable trigger function for raising exceptions, useful for debugging or enforcing logic constraints.

## Installation

To install and deploy this utility with LaunchQL CLI:

```bash
npm install -g @launchql/cli

cd /path/to/launchql/utils/totp

lql deploy \
  --recursive \
  --fast \
  --createdb \
  --yes \
  --database mydb \
  --project launchql-totp
```

## Usage

### `utils.mask_pad(bitstr text, bitlen int, pad text DEFAULT '0') → text`

**Purpose**:
Pads a binary string (as text) on the left with a specified character (default `'0'`) to a given length, or truncates it from the left if it's longer than `bitlen`.

**Example**:

```sql
SELECT utils.mask_pad('101', 6);         -- Returns '000101'
SELECT utils.mask_pad('11110000', 4);    -- Returns '0000'
SELECT utils.mask_pad('1', 3, 'x');      -- Returns 'xx1'
```

---

### `utils.bitmask_pad(bitstr VARBIT, bitlen int, pad text DEFAULT '0') → VARBIT`

**Purpose**:
Same as `mask_pad`, but for native PostgreSQL `VARBIT` (variable-length bit string) values. Outputs a `VARBIT` result.

**Example**:

```sql
SELECT utils.bitmask_pad(B'101', 6);          -- Returns B'000101'
SELECT utils.bitmask_pad(B'11110000', 4);     -- Returns B'0000'
SELECT utils.bitmask_pad(B'1', 3, '1');       -- Returns B'111'
```

---

### `utils.throw() → TRIGGER`

**Purpose**:
Custom trigger function that raises an exception when triggered. Useful for enforcing invariants, debugging, or intentional operation blocking.

**Trigger Arguments**:

* If **1 argument**: it becomes the error message.
* If **2 arguments**: both are included in the error.
* If **0 or more than 2**: default fallback message.

**Example**:

```sql
-- Example table
CREATE TABLE protected_actions (
  id serial PRIMARY KEY,
  action text
);

-- Add trigger to block inserts with custom message
CREATE TRIGGER block_insert
BEFORE INSERT ON protected_actions
FOR EACH ROW EXECUTE FUNCTION utils.throw('Insert operation blocked');

-- Attempting to insert will now raise an exception:
-- ERROR:  Insert operation blocked (protected_actions)
```

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

