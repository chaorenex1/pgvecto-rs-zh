\set ON_ERROR_STOP on

\echo '== pg_stat_statements =='

SELECT COUNT(*) AS tracked_statement_count

FROM pg_stat_statements;

SELECT queryid,

       calls,

       LEFT(query, 120) AS sample_query

FROM pg_stat_statements

ORDER BY calls DESC, total_exec_time DESC

LIMIT 5;

