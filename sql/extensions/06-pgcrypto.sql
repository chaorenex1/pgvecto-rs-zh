\set ON_ERROR_STOP on

\echo '== pgcrypto =='

SELECT encode(digest('minir-pg', 'sha256'), 'hex') AS sha256_hex,

       crypt('secret', gen_salt('bf')) <> 'secret' AS bcrypt_works;

