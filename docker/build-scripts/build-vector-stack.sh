#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

SOURCES_DIR=${1:?source directory is required}
export PATH=/root/.cargo/bin:/usr/local/pgsql/bin:$PATH
export PG_CONFIG=/usr/local/pgsql/bin/pg_config
export LLVM_CONFIG=${LLVM_CONFIG:-$(command -v llvm-config || true)}

build_pgvector() {
  local dir="${SOURCES_DIR}/pgvector"
  require_dir "$dir"

  log_step "Building pgvector"
  run_pgxs_make "$dir"
  make -C "$dir" PG_CONFIG="$PG_CONFIG" install
}

build_vectorchord() {
  local dir="${SOURCES_DIR}/vectorchord"
  require_dir "$dir"

  log_step "Building VectorChord"
  make -C "$dir" PG_CONFIG="$PG_CONFIG" build
  make -C "$dir" PG_CONFIG="$PG_CONFIG" install
}

build_pgvector
build_vectorchord
