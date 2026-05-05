ALTER DATABASE postgres SET search_path = public;
CREATE SCHEMA IF NOT EXISTS public;
SET search_path = public;

CREATE EXTENSION IF NOT EXISTS pg_tokenizer CASCADE;
CREATE EXTENSION IF NOT EXISTS vchord_bm25 CASCADE;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS vchord CASCADE;
CREATE EXTENSION IF NOT EXISTS pg_jieba WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS age;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS pgaudit;
CREATE EXTENSION IF NOT EXISTS amcheck;
CREATE EXTENSION IF NOT EXISTS pg_repack;
CREATE EXTENSION IF NOT EXISTS pgroonga;
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE SCHEMA IF NOT EXISTS partman;
CREATE EXTENSION IF NOT EXISTS pg_partman WITH SCHEMA partman;

DROP TEXT SEARCH CONFIGURATION IF EXISTS public.jieba_cfg;
CREATE TEXT SEARCH CONFIGURATION public.jieba_cfg (PARSER = jieba);
ALTER TEXT SEARCH CONFIGURATION public.jieba_cfg
    ADD MAPPING FOR n, v, a, i, e, l WITH simple;

CREATE OR REPLACE FUNCTION public.to_jieba_tsvector(text)
RETURNS tsvector AS $$
    SELECT to_tsvector('public.jieba_cfg', $1);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.to_jieba_tsquery(text)
RETURNS tsquery AS $$
    SELECT to_tsquery('public.jieba_cfg', $1);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.create_jieba_index(tbl regclass, col text)
RETURNS void AS $$
DECLARE
    idxname text;
BEGIN
    idxname := format('ix_%s_%s_jieba', tbl::text, col);

    EXECUTE format(
        'CREATE INDEX IF NOT EXISTS %I ON %s USING gin (to_tsvector(''public.jieba_cfg'', %I))',
        idxname, tbl, col
    );
END;
$$ LANGUAGE plpgsql;

BEGIN;
LOAD 'age';
SET LOCAL search_path = ag_catalog, "$user", public;

DO $block$
BEGIN
  IF NOT EXISTS (
      SELECT 1
      FROM ag_catalog.ag_graph
      WHERE name = 'sample_graph'
  ) THEN
      PERFORM ag_catalog.create_graph('sample_graph');
  END IF;
END;
$block$;

COMMIT;

\connect template1

ALTER DATABASE template1 SET search_path = public;
CREATE SCHEMA IF NOT EXISTS public;
SET search_path = public;

CREATE EXTENSION IF NOT EXISTS pg_tokenizer CASCADE;
CREATE EXTENSION IF NOT EXISTS vchord_bm25 CASCADE;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS vchord CASCADE;
CREATE EXTENSION IF NOT EXISTS pg_jieba WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS age;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS pgaudit;
CREATE EXTENSION IF NOT EXISTS amcheck;
CREATE EXTENSION IF NOT EXISTS pg_repack;
CREATE EXTENSION IF NOT EXISTS pgroonga;
CREATE SCHEMA IF NOT EXISTS partman;
CREATE EXTENSION IF NOT EXISTS pg_partman WITH SCHEMA partman;

DROP TEXT SEARCH CONFIGURATION IF EXISTS public.jieba_cfg;
CREATE TEXT SEARCH CONFIGURATION public.jieba_cfg (PARSER = jieba);
ALTER TEXT SEARCH CONFIGURATION public.jieba_cfg
    ADD MAPPING FOR n, v, a, i, e, l WITH simple;

CREATE OR REPLACE FUNCTION public.to_jieba_tsvector(text)
RETURNS tsvector AS $$
    SELECT to_tsvector('public.jieba_cfg', $1);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.to_jieba_tsquery(text)
RETURNS tsquery AS $$
    SELECT to_tsquery('public.jieba_cfg', $1);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.create_jieba_index(tbl regclass, col text)
RETURNS void AS $$
DECLARE
    idxname text;
BEGIN
    idxname := format('ix_%s_%s_jieba', tbl::text, col);

    EXECUTE format(
        'CREATE INDEX IF NOT EXISTS %I ON %s USING gin (to_tsvector(''public.jieba_cfg'', %I))',
        idxname, tbl, col
    );
END;
$$ LANGUAGE plpgsql;

BEGIN;
LOAD 'age';
SET LOCAL search_path = ag_catalog, "$user", public;

DO $block$
BEGIN
  IF NOT EXISTS (
      SELECT 1
      FROM ag_catalog.ag_graph
      WHERE name = 'sample_graph'
  ) THEN
      PERFORM ag_catalog.create_graph('sample_graph');
  END IF;
END;
$block$;

COMMIT;
