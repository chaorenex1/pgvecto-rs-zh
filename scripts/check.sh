#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="${SERVICE_NAME:-postgres}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-postgres}"

run_sql() {
  local script_path=$1
  echo "== running ${script_path} =="
  docker compose exec "$SERVICE_NAME" \
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$script_path"
}

run_sql /runtime/sql/inspection.sql
run_sql /runtime/sql/extensions/00-run-all.sql
run_sql /runtime/sql/extensions/99-cleanup-check.sql

echo "All inspection and extension smoke tests passed."
