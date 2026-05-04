\set ON_ERROR_STOP on

\echo '== vector =='

BEGIN;

CREATE TABLE ext_test_vector_items (

  id integer PRIMARY KEY,

  embedding vector(3) NOT NULL

);

INSERT INTO ext_test_vector_items (id, embedding) VALUES

  (1, '[1,0,0]'),

  (2, '[0,1,0]'),

  (3, '[0,0,1]');

CREATE INDEX ext_test_vector_hnsw_idx

  ON ext_test_vector_items USING hnsw (embedding vector_l2_ops);

SELECT id,

       ROUND((embedding <-> '[1,0,0]')::numeric, 4) AS l2_distance

FROM ext_test_vector_items

ORDER BY embedding <-> '[1,0,0]'

LIMIT 3;

ROLLBACK;

