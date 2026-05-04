\set ON_ERROR_STOP on

\echo '== age =='

BEGIN;

LOAD 'age';

SET LOCAL search_path = ag_catalog, "$user", public;

SELECT name

FROM ag_catalog.ag_graph

WHERE name = 'sample_graph';

SELECT *

FROM cypher('sample_graph', $$ RETURN 1 $$) AS (result agtype);

ROLLBACK;

