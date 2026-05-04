# PGVecto-rs-zh: PostgreSQL Vector Search with Chinese Word Segmentation

This project provides a PostgreSQL Docker image integrated with 
- vector search (VectorChord / pgvecto-rs compatibility)
- Chinese word segmentation (pg_jieba)
- graph database functionality (Apache AGE)
- common operations/search/maintenance extensions (postgis, hstore, unaccent, vchord, pg_trgm, pg_cron, pg_stat_statements, pg_partman, PGroonga, btree_gin, pgaudit, amcheck, pg_repack)

making it convenient to handle Chinese vector search, full-text search, and graph data requirements.

## Features

- Based on PostgreSQL 18
- Integrated VectorChord (`vchord`) with the existing vector extension stack
- Integrated pg_jieba extension for Chinese word segmentation, solving the BM25 score 0 issue
- Integrated Apache AGE extension for graph database functionality (supports pg11-18)
- Integrated common PostgreSQL ops/search/GIS extensions: postgis, hstore, unaccent, pg_trgm, pg_cron, pg_stat_statements, pg_partman, PGroonga, btree_gin, pgaudit, amcheck, pg_repack
- Pre-configured optimized Chinese full-text search configuration
- Uses Chinese mirror sources to accelerate building

## docker build

```bash
bash build.sh
```

## Usage

### Starting the Service

```bash
# Build and start the container (first start)
docker compose up -d

# View logs
docker compose logs -f
```

### Initialization Information

When the container is started for the first time, the `init.sql` script will automatically perform the following operations:
- Create vector, Chinese search, graph, maintenance, and audit extensions
- Create `postgis`, `hstore`, `unaccent`, and `vchord`
- Configure jieba_cfg text search configuration (using jieba parser)
- Install `pg_cron` only in the `postgres` database, while the other requested extensions are also seeded into `template1`

The PostgreSQL runtime tuning is mounted from `postgresql.auto.conf`:
- 32 GB RAM / 16 CPU / 100 connections tuning profile
- `wal_compression = lz4` requires PostgreSQL to be compiled with `--with-lz4`
- `io_method = io_uring` requires PostgreSQL to be compiled with `--with-liburing`

If your data volume already exists, the initialization script will not execute automatically. You can execute it manually:

```bash
# Delete existing data volume and restart (will clear all data)
docker compose down -v
docker compose up -d

```

### Connecting to the Database

```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U postgres
```

### Verifying Successful Installation

You can check if the extensions and text search configuration have been successfully installed with the following commands:

```bash
# Check installed extensions
docker compose exec postgres psql -U postgres -c "SELECT extname, extversion FROM pg_extension;"

# Check the newly added extensions
docker compose exec postgres psql -U postgres -c "SELECT extname FROM pg_extension WHERE extname IN ('postgis','hstore','unaccent','vchord','pg_trgm','pg_cron','pg_stat_statements','pg_partman','pgroonga','btree_gin','pgaudit','amcheck','pg_repack') ORDER BY extname;"

# Check if jieba parser exists
docker compose exec postgres psql -U postgres -c "SELECT prsname FROM pg_ts_parser WHERE prsname LIKE 'jieba%';"

# Check if jieba_cfg has been created
docker compose exec postgres psql -U postgres -c "SELECT cfgname FROM pg_ts_config WHERE cfgname = 'jieba_cfg';"

# Check if AGE graph has been created
docker compose exec postgres psql -U postgres -c "SELECT * FROM ag_catalog.ag_graph;"
```

## References

- [pg_jieba GitHub Repository](https://github.com/jaiminpan/pg_jieba)
- [pgvecto-rs GitHub Repository](https://github.com/tensorchord/pgvecto.rs)
- [Apache AGE GitHub Repository](https://github.com/apache/age)
- [pgvector-zh](https://github.com/wang-h/pgvector-zh)
