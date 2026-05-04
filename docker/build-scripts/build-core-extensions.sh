#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

SOURCES_DIR=${1:?source directory is required}
export PATH=/usr/local/pgsql/bin:$PATH
export PG_CONFIG=/usr/local/pgsql/bin/pg_config

build_pg_jieba() {
  local dir="${SOURCES_DIR}/pg_jieba"
  require_dir "$dir"

  log_step "Building pg_jieba"
  cd "$dir"
  mkdir -p libjieba/deps

  if [[ -d libjieba/limonp && ! -d libjieba/deps/limonp ]]; then
    mv libjieba/limonp libjieba/deps/
  fi

  cmake -S . -B build -DPostgreSQL_PG_CONFIG="$PG_CONFIG"
  cmake --build build -j"$MAKE_JOBS"
  cmake --install build
}

build_pgxs_extension() {
  local name=$1
  local dir="${SOURCES_DIR}/${name}"

  log_step "Building ${name}"
  run_pgxs_make "$dir" USE_PGXS=1
  make -C "$dir" USE_PGXS=1 PG_CONFIG="$PG_CONFIG" install
}

build_pg_jieba
build_pgxs_extension age
build_pgxs_extension pg_cron
build_pgxs_extension pg_partman
build_pgxs_extension pgaudit
build_pgxs_extension pg_repack
