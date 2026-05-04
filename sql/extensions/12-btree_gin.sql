\set ON_ERROR_STOP on

\echo '== btree_gin =='

BEGIN;

CREATE TABLE ext_test_btree_gin_items (

  id integer NOT NULL,

  tag text NOT NULL

);

INSERT INTO ext_test_btree_gin_items (id, tag) VALUES

  (1, 'alpha'),

  (2, 'beta'),

  (3, 'gamma');

CREATE INDEX ext_test_btree_gin_idx

  ON ext_test_btree_gin_items USING gin (id, tag);

SELECT *

FROM ext_test_btree_gin_items

WHERE id = 2 AND tag = 'beta';

ROLLBACK;

