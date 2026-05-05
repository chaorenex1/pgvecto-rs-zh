\set ON_ERROR_STOP on

\echo '== vchord_bm25 =='

BEGIN;

CREATE TABLE ext_test_vchord_bm25_docs (

  id integer PRIMARY KEY,

  content text NOT NULL,

  embedding bm25vector

);

SELECT tokenizer_catalog.create_text_analyzer('ext_test_bm25_analyzer', $$
pre_tokenizer = "unicode_segmentation"
[[character_filters]]
to_lowercase = {}
[[token_filters]]
skip_non_alphanumeric = {}
$$);

SELECT tokenizer_catalog.create_custom_model('ext_test_bm25_model', $$
table = 'ext_test_vchord_bm25_docs'
column = 'content'
text_analyzer = 'ext_test_bm25_analyzer'
$$);

SELECT tokenizer_catalog.create_tokenizer('ext_test_bm25_tokenizer', $$
text_analyzer = 'ext_test_bm25_analyzer'
model = 'ext_test_bm25_model'
$$);

INSERT INTO ext_test_vchord_bm25_docs (id, content) VALUES

  (1, 'PostgreSQL powers text search and ranking'),

  (2, 'VectorChord bm25 extends PostgreSQL search'),

  (3, 'Unrelated weather forecast example');

UPDATE ext_test_vchord_bm25_docs

SET embedding = tokenizer_catalog.tokenize(content, 'ext_test_bm25_tokenizer')::bm25vector;

CREATE INDEX ext_test_vchord_bm25_idx

  ON ext_test_vchord_bm25_docs USING bm25 (embedding bm25_ops);

SET LOCAL enable_seqscan = off;

EXPLAIN (COSTS OFF)

SELECT id

FROM ext_test_vchord_bm25_docs

ORDER BY embedding <&> bm25query(

  'ext_test_vchord_bm25_idx',

  tokenizer_catalog.tokenize('PostgreSQL search', 'ext_test_bm25_tokenizer')

)

LIMIT 2;

SELECT id

FROM ext_test_vchord_bm25_docs

ORDER BY embedding <&> bm25query(

  'ext_test_vchord_bm25_idx',

  tokenizer_catalog.tokenize('PostgreSQL search', 'ext_test_bm25_tokenizer')

)

LIMIT 2;

ROLLBACK;
