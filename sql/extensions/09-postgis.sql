\set ON_ERROR_STOP on

\echo '== postgis =='

SELECT postgis_full_version() AS postgis_version;

SELECT ST_AsText(ST_Buffer(ST_GeomFromText('POINT(0 0)'), 1)) AS buffered_point;

