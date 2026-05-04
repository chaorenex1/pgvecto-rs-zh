\set ON_ERROR_STOP on

\echo '== pg_trgm =='

SELECT show_trgm('minir pg') AS trigrams,

       similarity('postgres', 'postgre') AS similarity_score;

