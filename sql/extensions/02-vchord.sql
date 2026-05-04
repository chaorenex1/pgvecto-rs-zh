\set ON_ERROR_STOP on

\echo '== vchord =='

BEGIN;

CREATE TABLE ext_test_vchord_items (

  id integer PRIMARY KEY,

  embedding vector(3) NOT NULL

);

INSERT INTO ext_test_vchord_items (id, embedding) VALUES

  (1, '[1,0,0]'),

  (2, '[0.9,0.1,0]'),

  (3, '[0,1,0]');

CREATE INDEX ext_test_vchord_idx

  ON ext_test_vchord_items USING vchordrq (embedding vector_l2_ops);

SET LOCAL enable_seqscan = off;

EXPLAIN (COSTS OFF)

SELECT id

FROM ext_test_vchord_items

ORDER BY embedding <-> '[1,0,0]'

LIMIT 2;

SELECT id

FROM ext_test_vchord_items

ORDER BY embedding <-> '[1,0,0]'

LIMIT 2;

ROLLBACK;

