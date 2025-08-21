# PGVecto-rs-zh: PostgreSQL Vector Search with Chinese Word Segmentation

This project provides a PostgreSQL Docker image integrated with 
- vector search (pgvecto-rs)
- Chinese word segmentation (pg_jieba)
- graph database functionality (Apache AGE)

making it convenient to handle Chinese vector search, full-text search, and graph data requirements.

## Features

- Based on PostgreSQL 16
- Integrated pgvecto-rs extension for vector search
- Integrated pg_jieba extension for Chinese word segmentation, solving the BM25 score 0 issue
- Integrated Apache AGE extension for graph database functionality (supports pg12-16 only)
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
- Create vector and pg_jieba extensions
- Configure jieba_cfg text search configuration (using jieba parser)

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