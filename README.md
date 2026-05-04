# pgvecto-rs-zh

This project builds a PostgreSQL 18 image from an `ubuntu:24.04` base, compiles PostgreSQL with `--with-lz4` and `--with-liburing`, and then installs the full extension stack from source where practical.

## What is baked into the image

- PostgreSQL built from source with LZ4 and io_uring support
- Chinese text search with `pg_jieba`
- Graph support with `Apache AGE`
- Scheduling, auditing, partitioning, and maintenance extensions
- PostGIS, PGroonga, pgvector, and VectorChord
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
docker compose up -d --build
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
docker compose exec postgres psql -U postgres -c "SELECT name, default_version FROM pg_available_extensions WHERE name IN ('age','amcheck','btree_gin','hstore','pgaudit','pg_cron','pg_jieba','pg_partman','pg_repack','pg_stat_statements','pg_trgm','pgcrypto','pgroonga','postgis','unaccent','uuid-ossp','vchord','vector') ORDER BY name;"
```
