\set ON_ERROR_STOP on

\echo '== uuid-ossp =='

SELECT uuid_nil() AS nil_uuid,

       uuid_ns_dns() AS dns_namespace,

       uuid_generate_v4() AS sample_uuid_v4;

