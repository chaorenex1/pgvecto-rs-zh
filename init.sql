-- 创建必要的扩展
CREATE EXTENSION IF NOT EXISTS vectors;
CREATE EXTENSION IF NOT EXISTS pg_jieba;
CREATE EXTENSION IF NOT EXISTS age;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 创建基于pg_jieba的中文全文搜索配置
DO $BLOCK$
BEGIN
  -- 检查中文搜索配置是否已存在
  IF NOT EXISTS (
      SELECT 1 FROM pg_ts_config
      WHERE cfgname = 'jieba_cfg'
  ) THEN
      -- 创建中文全文搜索配置
      EXECUTE 'CREATE TEXT SEARCH CONFIGURATION jieba_cfg (PARSER = jieba)';
      EXECUTE 'ALTER TEXT SEARCH CONFIGURATION jieba_cfg ADD MAPPING FOR n,v,a,i,e,l WITH simple';
      RAISE NOTICE 'Text search configuration jieba_cfg created.';
  ELSE
      RAISE NOTICE 'Text search configuration jieba_cfg already exists.';
  END IF;
END;
$BLOCK$;

-- 加载AGE扩展并设置搜索路径
LOAD 'age';
SET search_path = ag_catalog, "$user", public;

-- 创建一个示例图
SELECT create_graph('sample_graph');

-- 切换到 template1，保证所有新库都会继承配置
\c template1;
-------------------------------
-- 默认 schema 设置
-------------------------------
-- 把 search_path 固定为 public，避免落到别的 schema
ALTER DATABASE template1 SET search_path = public;

-- 确保 public 存在
CREATE SCHEMA IF NOT EXISTS public;

SET search_path = public;

-------------------------------
-- 基础扩展
-------------------------------
-- UUID 生成扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
-- 中文分词扩展
CREATE EXTENSION IF NOT EXISTS pg_jieba WITH SCHEMA public;
-- 向量扩展
CREATE EXTENSION IF NOT EXISTS vectors;
-- AGE 扩展
CREATE EXTENSION IF NOT EXISTS age;
-- 加密扩展
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA public;

-------------------------------
-- 中文全文检索配置
-------------------------------
-- 删除旧配置，避免重复
DROP TEXT SEARCH CONFIGURATION IF EXISTS public.jieba_cfg;

-- 从 pg_jieba 拷贝配置
CREATE TEXT SEARCH CONFIGURATION public.jieba_cfg ( PARSER = jieba );

-- 给常见词性添加 simple 映射（名词、动词、形容词、习语、叹词、外来词）
ALTER TEXT SEARCH CONFIGURATION public.jieba_cfg
    ADD MAPPING FOR n, v, a, i, e, l WITH simple;

-------------------------------
-- 常用函数
-------------------------------
-- 统一的全文向量函数，避免每次写 to_tsvector('jieba_cfg', col)
CREATE OR REPLACE FUNCTION public.to_jieba_tsvector(text)
RETURNS tsvector AS $$
    SELECT to_tsvector('public.jieba_cfg', $1);
$$ LANGUAGE sql IMMUTABLE;

-- 统一的查询函数，简化 to_tsquery('jieba_cfg', query)
CREATE OR REPLACE FUNCTION public.to_jieba_tsquery(text)
RETURNS tsquery AS $$
    SELECT to_tsquery('public.jieba_cfg', $1);
$$ LANGUAGE sql IMMUTABLE;

-------------------------------
-- 常用索引模板（示例）
-------------------------------
-- 在新库中，只需：
--   CREATE TABLE articles (id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), content TEXT);
--   SELECT create_jieba_index('articles', 'content');
-- 即可自动创建索引

CREATE OR REPLACE FUNCTION public.create_jieba_index(tbl regclass, col text)
RETURNS void AS $$
DECLARE
    idxname text;
BEGIN
    -- 索引名自动生成： ix_<table>_<column>_jieba
    idxname := format('ix_%s_%s_jieba', tbl::text, col);

    EXECUTE format(
        'CREATE INDEX IF NOT EXISTS %I ON %s USING gin (to_tsvector(''public.jieba_cfg'', %I))',
        idxname, tbl, col
    );
END;
$$ LANGUAGE plpgsql;
