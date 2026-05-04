\set ON_ERROR_STOP on

\echo '== hstore =='

SELECT ('a=>1,b=>2'::hstore -> 'a') AS value_for_a,

       akeys('a=>1,b=>2'::hstore) AS hstore_keys;

