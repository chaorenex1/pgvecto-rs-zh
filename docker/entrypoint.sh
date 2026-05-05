#!/usr/bin/env bash
set -euo pipefail

export PATH=/usr/local/pgsql/bin:$PATH
export PGDATA=${PGDATA:-/var/lib/postgresql/data}
export POSTGRES_USER=${POSTGRES_USER:-postgres}
export POSTGRES_DB=${POSTGRES_DB:-$POSTGRES_USER}
export POSTGRES_CONFIG_FILE=${POSTGRES_CONFIG_FILE:-/etc/postgresql/postgresql.conf}
export POSTGRES_FALLBACK_CONFIG_FILE=${POSTGRES_FALLBACK_CONFIG_FILE:-/etc/postgresql/postgresql.conf}
export POSTGRES_IO_METHOD=${POSTGRES_IO_METHOD:-}
export POSTGRES_INIT_MARKER_FILE=${POSTGRES_INIT_MARKER_FILE:-$PGDATA/.container_init_completed}

warn_permission_issue() {
  echo "warning: $*" >&2
}

resolve_postgres_config_file() {
  if [[ -f "$POSTGRES_CONFIG_FILE" ]]; then
    printf '%s\n' "$POSTGRES_CONFIG_FILE"
    return 0
  fi

  if [[ -f "$POSTGRES_FALLBACK_CONFIG_FILE" ]]; then
    echo "custom postgres config not found at $POSTGRES_CONFIG_FILE, falling back to $POSTGRES_FALLBACK_CONFIG_FILE" >&2
    printf '%s\n' "$POSTGRES_FALLBACK_CONFIG_FILE"
    return 0
  fi

  echo "postgres config file not found: $POSTGRES_CONFIG_FILE"
  echo "postgres fallback config file not found: $POSTGRES_FALLBACK_CONFIG_FILE"
  exit 1
}

prepare_pgdata_dir() {
  local probe_file

  mkdir -p "$PGDATA"

  if ! chmod 700 "$PGDATA" 2>/dev/null; then
    warn_permission_issue "could not chmod 700 $PGDATA; continuing with existing host filesystem permissions"
  fi

  probe_file="$PGDATA/.write-test.$$"
  if ! : > "$probe_file" 2>/dev/null; then
    echo "PGDATA is not writable: $PGDATA" >&2
    ls -ld "$PGDATA" >&2 || true
    exit 1
  fi
  rm -f "$probe_file"
}

build_postgres_runtime_options() {
  local config_file=$1
  local options=("-c" "config_file=$config_file")

  if [[ -n "$POSTGRES_IO_METHOD" ]]; then
    options+=("-c" "io_method=$POSTGRES_IO_METHOD")
  fi

  printf '%s\n' "${options[@]}"
}

run_init_scripts() {
  local file
  shopt -s nullglob
  for file in /docker-entrypoint-initdb.d/*; do
    case "$file" in
      *.sh)
        echo "running $file"
        bash "$file"
        ;;
      *.sql)
        echo "running $file"
        psql -v ON_ERROR_STOP=1 --username postgres --dbname postgres -f "$file"
        ;;
      *)
        echo "ignoring $file"
        ;;
    esac
  done
}

create_app_database() {
  if [[ "$POSTGRES_DB" == postgres ]]; then
    return 0
  fi

  psql \
    -v ON_ERROR_STOP=1 \
    --username postgres \
    --dbname postgres \
    --set=app_db="$POSTGRES_DB" \
    --set=app_user="$POSTGRES_USER" <<'SQL'
SELECT format(
  'CREATE DATABASE %I WITH OWNER %I TEMPLATE template1',
  :'app_db',
  :'app_user'
)
WHERE NOT EXISTS (
  SELECT 1
  FROM pg_database
  WHERE datname = :'app_db'
)\gexec

SELECT format(
  'ALTER DATABASE %I SET search_path = public',
  :'app_db'
)\gexec
SQL
}

run_post_init_tasks() {
  if [[ -z "${POSTGRES_PASSWORD:-}" ]]; then
    echo "POSTGRES_PASSWORD must be set for initialization tasks"
    exit 1
  fi

  pg_ctl -D "$PGDATA" -o "-c listen_addresses='' ${POSTGRES_RUNTIME_OPTIONS[*]}" -w start

  if [[ "$POSTGRES_USER" != postgres ]]; then
    psql \
      -v ON_ERROR_STOP=1 \
      --username postgres \
      --dbname postgres \
      --set=app_user="$POSTGRES_USER" \
      --set=app_password="$POSTGRES_PASSWORD" <<'SQL'
SELECT format(
  'CREATE ROLE %I WITH LOGIN SUPERUSER PASSWORD %L',
  :'app_user',
  :'app_password'
)
WHERE NOT EXISTS (
  SELECT 1
  FROM pg_roles
  WHERE rolname = :'app_user'
)\gexec
SQL
  else
    psql \
      -v ON_ERROR_STOP=1 \
      --username postgres \
      --dbname postgres \
      --set=app_password="$POSTGRES_PASSWORD" <<'SQL'
SELECT format(
  'ALTER ROLE postgres WITH PASSWORD %L',
  :'app_password'
)\gexec
SQL
  fi

  run_init_scripts
  create_app_database
  touch "$POSTGRES_INIT_MARKER_FILE"
  pg_ctl -D "$PGDATA" -m fast -w stop
}

if [[ $# -eq 0 ]]; then
  set -- postgres
elif [[ "$1" == -* ]]; then
  set -- postgres "$@"
fi

if [[ "$1" != postgres ]]; then
  exec "$@"
fi

if [[ $(id -u) -eq 0 ]]; then
  mkdir -p "$PGDATA" /var/run/postgresql
  if ! chown postgres:postgres "$PGDATA" 2>/dev/null; then
    warn_permission_issue "could not chown $PGDATA to postgres:postgres; bind-mounted host directories may ignore container ownership changes"
  fi
  chown -R postgres:postgres /var/lib/postgresql /var/run/postgresql
  chmod 2775 /var/run/postgresql
  sysctl --system >/dev/null 2>&1 || echo "warning: some sysctl values could not be applied inside the container"
  exec gosu postgres "$BASH_SOURCE" "$@"
fi

prepare_pgdata_dir

ACTIVE_POSTGRES_CONFIG_FILE=$(resolve_postgres_config_file)
mapfile -t POSTGRES_RUNTIME_OPTIONS < <(build_postgres_runtime_options "$ACTIVE_POSTGRES_CONFIG_FILE")

if [[ ! -s "$PGDATA/PG_VERSION" ]]; then
  if [[ -z "${POSTGRES_PASSWORD:-}" ]]; then
    echo "POSTGRES_PASSWORD must be set for first-time initialization"
    exit 1
  fi

  tmp_pw=$(mktemp)
  trap 'rm -f "$tmp_pw"' EXIT
  printf '%s\n' "$POSTGRES_PASSWORD" > "$tmp_pw"

  initdb --username=postgres --pwfile="$tmp_pw" --auth-local=trust --auth-host=scram-sha-256 ${POSTGRES_INITDB_ARGS:-} -D "$PGDATA"
  echo "host all all all scram-sha-256" >> "$PGDATA/pg_hba.conf"
fi

if [[ ! -f "$POSTGRES_INIT_MARKER_FILE" ]]; then
  run_post_init_tasks
fi

exec postgres -D "$PGDATA" "${POSTGRES_RUNTIME_OPTIONS[@]}"
