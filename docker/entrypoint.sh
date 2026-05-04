#!/usr/bin/env bash
set -euo pipefail

export PATH=/usr/local/pgsql/bin:$PATH
export PGDATA=${PGDATA:-/var/lib/postgresql/data}
export POSTGRES_USER=${POSTGRES_USER:-postgres}
export POSTGRES_DB=${POSTGRES_DB:-$POSTGRES_USER}
export POSTGRES_CONFIG_FILE=${POSTGRES_CONFIG_FILE:-/etc/postgresql/postgresql.conf}

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
  chown -R postgres:postgres /var/lib/postgresql /var/run/postgresql
  chmod 2775 /var/run/postgresql
  sysctl --system >/dev/null 2>&1 || echo "warning: some sysctl values could not be applied inside the container"
  exec gosu postgres "$BASH_SOURCE" "$@"
fi

mkdir -p "$PGDATA"
chmod 700 "$PGDATA"

if [[ ! -f "$POSTGRES_CONFIG_FILE" ]]; then
  echo "postgres config file not found: $POSTGRES_CONFIG_FILE"
  exit 1
fi

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

  pg_ctl -D "$PGDATA" -o "-c listen_addresses='' -c config_file=$POSTGRES_CONFIG_FILE" -w start

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

  if [[ "$POSTGRES_DB" != postgres ]]; then
    psql \
      -v ON_ERROR_STOP=1 \
      --username postgres \
      --dbname postgres \
      --set=app_db="$POSTGRES_DB" \
      --set=app_user="$POSTGRES_USER" <<'SQL'
SELECT format(
  'CREATE DATABASE %I OWNER %I',
  :'app_db',
  :'app_user'
)
WHERE NOT EXISTS (
  SELECT 1
  FROM pg_database
  WHERE datname = :'app_db'
)\gexec
SQL
  fi

  run_init_scripts
  pg_ctl -D "$PGDATA" -m fast -w stop
fi

exec postgres -D "$PGDATA" -c config_file="$POSTGRES_CONFIG_FILE"
