\set ON_ERROR_STOP on

\echo '== pgroonga =='

BEGIN;

CREATE TABLE ext_test_pgroonga_docs (

  id integer PRIMARY KEY,

  content text NOT NULL

);

INSERT INTO ext_test_pgroonga_docs (id, content) VALUES

  (1, 'PostgreSQL extension for fast full text search'),

  (2, 'Vector search and graph support'),

  (3, 'Chinese tokenizer with jieba');

CREATE INDEX ext_test_pgroonga_idx

  ON ext_test_pgroonga_docs

  USING pgroonga (content pgroonga_text_full_text_search_ops_v2);

SELECT id,

       content,

       pgroonga_score(tableoid, ctid) AS score

FROM ext_test_pgroonga_docs

WHERE content &@~ 'PostgreSQL OR search'

ORDER BY id;

ROLLBACK;

