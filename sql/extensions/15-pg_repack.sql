\set ON_ERROR_STOP on

\echo '== pg_repack =='

SELECT repack.version() AS repack_library_version,

       repack.version_sql() AS repack_sql_version;

