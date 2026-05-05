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
  require_dir "$dir"

  log_step "Building VectorChord-bm25"
  make -C "$dir" PG_CONFIG="$PG_CONFIG" build
  make -C "$dir" PG_CONFIG="$PG_CONFIG" install
}

build_pg_tokenizer() {
  local dir="${SOURCES_DIR}/pg_tokenizer.rs"
  local version="${PG_TOKENIZER_VERSION:?PG_TOKENIZER_VERSION is required}"
  local feature="pg${PG_MAJOR:?PG_MAJOR is required}"
  local pkglibdir
  local extension_dir
  require_dir "$dir"

  log_step "Building pg_tokenizer.rs"
  pkglibdir=$("$PG_CONFIG" --pkglibdir)
  extension_dir="$("$PG_CONFIG" --sharedir)/extension"

  cd "$dir"
  cargo build --lib --features "$feature" --release

  install -d "$pkglibdir" "$extension_dir"
  install -m 755 target/release/libpg_tokenizer.so "${pkglibdir}/pg_tokenizer.so"
  sed -e "s/@CARGO_VERSION@/${version}/g" < pg_tokenizer.control > "${extension_dir}/pg_tokenizer.control"
  install -m 644 "sql/install/pg_tokenizer--${version}.sql" "${extension_dir}/pg_tokenizer--${version}.sql"

  if [[ -d sql/upgrade ]]; then
    install -m 644 sql/upgrade/pg_tokenizer--*.sql "$extension_dir/"
  fi
}

build_pgvector
build_vectorchord
build_vectorchord_bm25
build_pg_tokenizer
