\set ON_ERROR_STOP on

\echo '== pgaudit =='

SELECT extversion

FROM pg_extension

WHERE extname = 'pgaudit';

SELECT name, setting, source

FROM pg_settings

WHERE name LIKE 'pgaudit.%'

ORDER BY name;

