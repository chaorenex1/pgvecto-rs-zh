\set ON_ERROR_STOP on

\echo '== pg_tokenizer =='

BEGIN;

CREATE TABLE ext_test_pg_tokenizer_docs (

  id integer PRIMARY KEY,

  content text NOT NULL,

  embedding integer[]

);

SELECT tokenizer_catalog.create_text_analyzer('ext_test_analyzer', $$
pre_tokenizer = "unicode_segmentation"
[[character_filters]]
to_lowercase = {}
[[token_filters]]
skip_non_alphanumeric = {}
$$);

SELECT tokenizer_catalog.create_custom_model_tokenizer_and_trigger(

  tokenizer_name => 'ext_test_tokenizer',

  model_name => 'ext_test_model',

  text_analyzer_name => 'ext_test_analyzer',

  table_name => 'ext_test_pg_tokenizer_docs',

  source_column => 'content',

  target_column => 'embedding'

);

INSERT INTO ext_test_pg_tokenizer_docs (id, content) VALUES

  (1, 'PostgreSQL search ranking'),

  (2, 'VectorChord bm25 tokenizer integration');

SELECT id, cardinality(embedding) AS token_count

FROM ext_test_pg_tokenizer_docs

ORDER BY id;

SELECT tokenizer_catalog.tokenize('PostgreSQL search ranking', 'ext_test_tokenizer') AS token_ids;

ROLLBACK;
