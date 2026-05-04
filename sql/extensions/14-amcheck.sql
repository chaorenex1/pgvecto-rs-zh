\set ON_ERROR_STOP on

\echo '== amcheck =='

BEGIN;

CREATE TABLE ext_test_amcheck_items (

  id integer PRIMARY KEY,

  payload text NOT NULL

);

INSERT INTO ext_test_amcheck_items (id, payload)

SELECT g, 'payload-' || g

FROM generate_series(1, 10) AS g;

SELECT bt_index_check('ext_test_amcheck_items_pkey'::regclass);

ROLLBACK;

