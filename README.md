# LaunchQL Utils

<p align="center" width="100%">
  <img height="250" src="https://raw.githubusercontent.com/launchql/launchql/refs/heads/main/assets/outline-logo.svg" />
</p>

<p align="center" width="100%">
  <a href="https://github.com/launchql/utils/actions/workflows/run-tests.yaml">
    <img height="20" src="https://github.com/launchql/utils/actions/workflows/run-tests.yaml/badge.svg" />
  </a>
   <a href="https://github.com/launchql/utils/blob/main/LICENSE"><img height="20" src="https://img.shields.io/badge/license-MIT-blue.svg"/></a>
</p>

A collection of PostgreSQL extensions and utilities for building robust, scalable database applications. LaunchQL Utils provides a suite of tools for common database operations, data types, and functionality that extends PostgreSQL's capabilities.

## Quick Start

### 1. Start the PostgreSQL Database

First, start the PostgreSQL Docker container:

```sh
# Using make
make up

# Or using docker-compose directly
docker-compose up -d
```

This will start a PostgreSQL instance with PostGIS support and mount your local `packages/` directory.

### 2. Install the LaunchQL CLI

The LaunchQL CLI is a powerful tool for managing your database projects:

```sh
npm install -g @launchql/cli
```

### 3. Install the PostgreSQL Extensions

Once the PostgreSQL process is running, install the extensions:

```sh
make install
```

This command connects to the PostgreSQL instance with the `packages/` folder mounted as a volume, and installs the bundled SQL code as PGXN extensions.

## Running Migrations

### Deploy a Single Extension

To deploy a specific extension (e.g., base32):

```sh
cd packages/base32

lql deploy \
  --recursive \
  --fast \
  --createdb \
  --yes \
  --database mydb \
  --project launchql-base32
```

## Available Extensions

LaunchQL Utils includes the following PostgreSQL extensions:

| Extension | Description |
|-----------|-------------|
| [utils](packages/utils) | Core utility functions for bitmask padding and custom trigger-based exceptions |
| [base32](packages/base32) | RFC4648 Base32 encode/decode in plpgsql |
| [totp](packages/totp) | Time-based One-Time Password (TOTP) implementation |
| [uuid](packages/uuid) | UUID generation and manipulation utilities |
| [jobs](packages/jobs) | Background job processing for PostgreSQL |
| [jobs-simple](packages/jobs-simple) | Simplified job queue implementation |
| [types](packages/types) | Custom data types and type handling |
| [defaults](packages/defaults) | Default value generators and utilities |
| [verify](packages/verify) | Verification and validation utilities |
| [measurements](packages/measurements) | Measurement and unit conversion utilities |
| [geotypes](packages/geotypes) | Geographic data type extensions |
| [inflection](packages/inflection) | String inflection utilities (pluralization, etc.) |
| [achievements](packages/achievements) | Achievement tracking system |
| [faker](packages/faker) | Fake data generation for testing |
| [jwt-claims](packages/jwt-claims) | JWT claim handling utilities |
| [default-roles](packages/default-roles) | Default role management |
| [stamps](packages/stamps) | Timestamp utilities and tracking |

Each extension can be installed individually or as part of a complete deployment.

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
