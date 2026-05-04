\set ON_ERROR_STOP on

\echo '== pg_partman =='

BEGIN;

CREATE SCHEMA ext_test_partman;

CREATE TABLE ext_test_partman.events (

  id bigint NOT NULL,

  created_at timestamptz NOT NULL DEFAULT now(),

  payload text

) PARTITION BY RANGE (created_at);

CREATE TABLE ext_test_partman.events_template (LIKE ext_test_partman.events);

ALTER TABLE ext_test_partman.events_template ADD PRIMARY KEY (id);

SELECT partman.create_partition(

  p_parent_table := 'ext_test_partman.events',

  p_control := 'created_at',

  p_interval := '1 day',

  p_template_table := 'ext_test_partman.events_template'

) AS partitions_created;

SELECT parent_table, control, partition_interval

FROM partman.part_config

WHERE parent_table = 'ext_test_partman.events';

SELECT COUNT(*) AS child_partition_count

FROM pg_inherits

WHERE inhparent = 'ext_test_partman.events'::regclass;

ROLLBACK;

