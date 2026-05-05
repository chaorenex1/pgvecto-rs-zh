\set ON_ERROR_STOP on

\echo '== pg_cron =='

\connect postgres

BEGIN;

WITH scheduled AS (

  SELECT cron.schedule(

           'minir-pg-smoke-test',

           '0 0 1 1 *',

           'SELECT 1'

         ) AS jobid

)

SELECT cron.unschedule(jobid) AS unscheduled

FROM scheduled;

SELECT schedule, command

FROM cron.job

WHERE jobname = 'minir-pg-smoke-test';

ROLLBACK;

\connect :template_db
