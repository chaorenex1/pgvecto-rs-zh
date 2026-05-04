\set ON_ERROR_STOP on

\echo '== pg_jieba =='

BEGIN;

SELECT cfgname
FROM pg_ts_config
WHERE cfgname = 'jieba_cfg';

SELECT to_tsvector('jieba_cfg', '南京市长江大桥') AS jieba_tokens;

CREATE TABLE ext_test_jieba_docs (
  id integer PRIMARY KEY,
  content text NOT NULL
);

CREATE INDEX ext_test_jieba_docs_jieba_idx
  ON ext_test_jieba_docs
  USING gin (to_tsvector('jieba_cfg', content));

INSERT INTO ext_test_jieba_docs (id, content) VALUES
  (1, '南京市长江大桥'),
  (2, '上海自贸区'),
  (3, '机器学习');

SELECT id, content
FROM ext_test_jieba_docs
WHERE to_tsvector('jieba_cfg', content) @@ to_tsquery('jieba_cfg', '南京')
ORDER BY id;

SELECT indexname
FROM pg_indexes
WHERE tablename = 'ext_test_jieba_docs'
ORDER BY indexname;

ROLLBACK;
