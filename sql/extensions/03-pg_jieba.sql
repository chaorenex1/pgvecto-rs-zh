\set ON_ERROR_STOP on

\echo '== pg_jieba =='

BEGIN;

SELECT cfgname

FROM pg_ts_config

WHERE cfgname = 'jieba_cfg';

SELECT public.to_jieba_tsvector('南京市长江大桥') AS jieba_tokens;

CREATE TABLE ext_test_jieba_docs (

  id integer PRIMARY KEY,

  content text NOT NULL

);

SELECT public.create_jieba_index('ext_test_jieba_docs'::regclass, 'content');

SELECT indexname

FROM pg_indexes

WHERE tablename = 'ext_test_jieba_docs'

ORDER BY indexname;

ROLLBACK;

