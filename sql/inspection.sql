\set ON_ERROR_STOP on

\pset pager off

\echo '== Instance overview =='

SELECT current_database() AS database_name,

       current_user AS current_user,

       version() AS postgres_version,

       now() AS inspected_at;

\echo '== Key performance settings =='

SELECT name, setting, unit, source

FROM pg_settings

WHERE name IN (

  'max_connections',

  'shared_buffers',

  'effective_cache_size',

  'maintenance_work_mem',

  'work_mem',

  'wal_buffers',

  'effective_io_concurrency',

  'io_workers',

  'min_wal_size',

  'max_wal_size',

  'wal_compression',

  'io_method',

  'shared_preload_libraries',

  'compute_query_id',

  'cron.database_name'

)

ORDER BY name;

\echo '== Installed extension versions =='

SELECT e.extname,

       e.extversion,

       n.nspname AS extension_schema

FROM pg_extension AS e

JOIN pg_namespace AS n ON n.oid = e.extnamespace

WHERE e.extname IN (

  'age','amcheck','btree_gin','hstore','pgaudit','pg_cron','pg_jieba',

  'pg_partman','pg_repack','pg_stat_statements','pg_trgm','pgcrypto',

  'pgroonga','postgis','unaccent','uuid-ossp','vchord','vector'

)

ORDER BY e.extname;

\echo '== Available extension catalog =='

SELECT name, default_version, installed_version

FROM pg_available_extensions

WHERE name IN (

  'age','amcheck','btree_gin','hstore','pgaudit','pg_cron','pg_jieba',

  'pg_partman','pg_repack','pg_stat_statements','pg_trgm','pgcrypto',

  'pgroonga','postgis','unaccent','uuid-ossp','vchord','vector'

)

ORDER BY name;

\echo '== Init objects =='

SELECT EXISTS (

         SELECT 1 FROM pg_ts_config WHERE cfgname = 'jieba_cfg'

       ) AS has_jieba_cfg,

       EXISTS (

         SELECT 1 FROM ag_catalog.ag_graph WHERE name = 'sample_graph'

       ) AS has_sample_graph,

       to_regprocedure('public.to_jieba_tsvector(text)') IS NOT NULL AS has_to_jieba_tsvector,

       to_regprocedure('public.create_jieba_index(regclass,text)') IS NOT NULL AS has_create_jieba_index,

       to_regnamespace('partman') IS NOT NULL AS has_partman_schema,

       to_regnamespace('cron') IS NOT NULL AS has_cron_schema,

       to_regnamespace('repack') IS NOT NULL AS has_repack_schema;

\echo '== Access methods =='

SELECT amname

FROM pg_am

WHERE amname IN ('hnsw', 'ivfflat', 'vchordrq', 'vchordg', 'pgroonga')

ORDER BY amname;

\echo '== Database activity =='

SELECT datname,

       numbackends,

       xact_commit,

       xact_rollback,

       blks_read,

       blks_hit,

       ROUND(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2) AS cache_hit_pct

FROM pg_stat_database

WHERE datname = current_database();

\echo '== Background writer =='

SELECT checkpoints_timed,

       checkpoints_req,

       buffers_checkpoint,

       buffers_clean,

       maxwritten_clean,

       buffers_backend,

       buffers_backend_fsync

FROM pg_stat_bgwriter;

\echo '== Top statements (if any) =='

SELECT queryid,

       calls,

       ROUND(total_exec_time::numeric, 3) AS total_exec_time_ms,

       ROUND(mean_exec_time::numeric, 3) AS mean_exec_time_ms,

       LEFT(query, 120) AS sample_query

FROM pg_stat_statements

ORDER BY total_exec_time DESC

LIMIT 10;

