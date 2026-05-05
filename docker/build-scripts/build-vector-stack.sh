#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

SOURCES_DIR=${1:?source directory is required}
PG_PREFIX=${PG_PREFIX:-/usr/local/pgsql18}
export PATH="/root/.cargo/bin:${PG_PREFIX}/bin:$PATH"
export PG_CONFIG="${PG_PREFIX}/bin/pg_config"
export LLVM_CONFIG=${LLVM_CONFIG:-$(command -v llvm-config || true)}
export PGRX_HOME=${PGRX_HOME:-/root/.pgrx}

init_pgrx() {
  log_step "Initializing cargo-pgrx for PostgreSQL ${PG_MAJOR}"
  cargo pgrx init "--pg${PG_MAJOR}=${PG_CONFIG}"
}

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

build_vectorchord_bm25() {
  local dir="${SOURCES_DIR}/vectorchord-bm25"
  local feature="pg${PG_MAJOR:?PG_MAJOR is required}"
  require_dir "$dir"

  log_step "Building VectorChord-bm25 with cargo-pgrx"
  cd "$dir"
  cargo pgrx install --release --features "$feature" --pg-config "$PG_CONFIG"
}

build_pg_tokenizer() {
  local dir="${SOURCES_DIR}/pg_tokenizer.rs"
  local feature="pg${PG_MAJOR:?PG_MAJOR is required}"
  require_dir "$dir"

  log_step "Building pg_tokenizer.rs with cargo-pgrx"
  cd "$dir"
  cargo pgrx install --release --features "$feature" --pg-config "$PG_CONFIG"
}

init_pgrx
build_pgvector
build_vectorchord
build_vectorchord_bm25
build_pg_tokenizer
