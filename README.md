# minir-pg

This project builds a PostgreSQL 18 image from an `ubuntu:24.04` base, compiles PostgreSQL with `--with-lz4` and `--with-liburing`, and then installs the full extension stack from source where practical.

## What is baked into the image

- PostgreSQL built from source with LZ4 and io_uring support
- Chinese text search with `pg_jieba`
- Graph support with `Apache AGE`
- Scheduling, auditing, partitioning, and maintenance extensions
- PostGIS, PGroonga, pgvector, VectorChord, VectorChord-bm25, and pg_tokenizer.rs
- Image-level PostgreSQL defaults, sysctl defaults, and init SQL

## Layout

- `docker/versions.env` - version pins and repository refs
- `docker/fetch-sources.sh` - downloads PostgreSQL and clones extension sources into `sources/`
- `docker/build-scripts/` - build helpers used inside the Docker build
- `docker/postgresql.conf` - baked-in PostgreSQL defaults
- `docker/initdb/00-init.sql` - first-boot initialization
- `docker/entrypoint.sh` - custom initdb and startup flow for the Ubuntu base image

## Usage

Fetch the sources first:

```bash
bash build.sh fetch
```

Build the image:

```bash
bash build.sh build
```

Or do both in one step:

```bash
bash build.sh all
```

Start the database:

```bash
docker compose up -d
```

Run the command from the repository root. If the repository root contains a
`postgresql.conf` file, the container will use it as the custom config. If that
file is missing, the container falls back to the baked-in
`/etc/postgresql/postgresql.conf` from the image. PostgreSQL data will be
initialized under `pgdata/` in the same directory so the compose file and
custom config can coexist without making `PGDATA` non-empty.
The container checks `/runtime/postgresql.conf` first, which comes from the
directory where `docker compose` is executed.
`POSTGRES_IO_METHOD` is controlled through compose environment variables and
defaults to `worker`.
For example:

```text
<runtime-dir>/
  postgresql.conf
  pgdata/
```

## Validation

Check the compile flags:

```bash
docker compose exec postgres pg_config --configure
```

Check the PostgreSQL settings:

```bash
docker compose exec postgres psql -U postgres -c "SHOW wal_compression;"
docker compose exec postgres psql -U postgres -c "SHOW io_method;"
```

Check extension availability:

```bash
docker compose exec postgres psql -U postgres -c "SELECT name, default_version FROM pg_available_extensions WHERE name IN ('age','amcheck','btree_gin','hstore','pgaudit','pg_cron','pg_jieba','pg_partman','pg_repack','pg_stat_statements','pg_trgm','pgcrypto','pg_tokenizer','pgroonga','postgis','unaccent','uuid-ossp','vchord','vchord_bm25','vector') ORDER BY name;"
```
