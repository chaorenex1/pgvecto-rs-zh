\set ON_ERROR_STOP on

\echo '== cleanup check =='

DO $$
DECLARE
  leftover_schemas text[];
  leftover_relations text[];
  leftover_cron_jobs text[];
BEGIN
  SELECT COALESCE(array_agg(nspname ORDER BY nspname), ARRAY[]::text[])
    INTO leftover_schemas
  FROM pg_namespace
  WHERE nspname LIKE 'ext_test_%';

  IF array_length(leftover_schemas, 1) IS NOT NULL THEN
    RAISE EXCEPTION 'leftover test schemas found: %', array_to_string(leftover_schemas, ', ');
  END IF;

  SELECT COALESCE(array_agg(format('%I.%I', n.nspname, c.relname) ORDER BY n.nspname, c.relname), ARRAY[]::text[])
    INTO leftover_relations
  FROM pg_class AS c
  JOIN pg_namespace AS n ON n.oid = c.relnamespace
  WHERE c.relname LIKE 'ext_test_%'
    AND n.nspname NOT IN ('pg_catalog', 'information_schema');

  IF array_length(leftover_relations, 1) IS NOT NULL THEN
    RAISE EXCEPTION 'leftover test relations found: %', array_to_string(leftover_relations, ', ');
  END IF;

  IF to_regnamespace('cron') IS NOT NULL THEN
    SELECT COALESCE(array_agg(jobname ORDER BY jobname), ARRAY[]::text[])
      INTO leftover_cron_jobs
    FROM cron.job
    WHERE jobname = 'minir-pg-smoke-test';

    IF array_length(leftover_cron_jobs, 1) IS NOT NULL THEN
      RAISE EXCEPTION 'leftover cron jobs found: %', array_to_string(leftover_cron_jobs, ', ');
    END IF;
  END IF;
END
$$;

SELECT 'cleanup check passed' AS status;
