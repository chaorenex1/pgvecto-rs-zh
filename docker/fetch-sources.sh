#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

set -a
source docker/versions.env
set +a

mkdir -p sources

log() {
  printf '\n==> %s\n' "$*"
}

download_postgres() {
  local tarball="sources/postgresql-${PG_VERSION}.tar.bz2"
  if [[ -f "$tarball" ]]; then
    log "Using cached PostgreSQL ${PG_VERSION} source tarball"
    return
  fi

  log "Downloading PostgreSQL ${PG_VERSION} source"
  curl --fail --location --silent --show-error "$POSTGRES_URL" -o "$tarball"
}

sync_repo() {
  local name=$1
  local repo=$2
  local ref=$3
  local with_submodules=${4:-0}
  local target="sources/${name}"

  log "Syncing ${name} @ ${ref}"

  if [[ ! -d "$target/.git" ]]; then
    git clone --quiet --filter=blob:none "$repo" "$target"
    git -C "$target" config advice.detachedHead false
  fi

  git -C "$target" remote set-url origin "$repo"
  git -C "$target" fetch --quiet --force --depth 1 --recurse-submodules=no origin "$ref"
  git -C "$target" checkout --quiet --force --detach FETCH_HEAD
  git -C "$target" clean -ffdq

  if [[ "$with_submodules" == "1" ]]; then
    git -C "$target" submodule sync --quiet --recursive
    git -C "$target" submodule update --init --recursive --depth 1 --jobs 4 --quiet
  fi
}

download_postgres
sync_repo pg_jieba "$PG_JIEBA_REPO" "$PG_JIEBA_REF" 1
sync_repo age "$AGE_REPO" "$AGE_REF"
sync_repo pg_cron "$PG_CRON_REPO" "$PG_CRON_REF"
sync_repo pg_partman "$PG_PARTMAN_REPO" "$PG_PARTMAN_REF"
sync_repo pgaudit "$PGAUDIT_REPO" "$PGAUDIT_REF"
sync_repo pg_repack "$PG_REPACK_REPO" "$PG_REPACK_REF"
sync_repo postgis "$POSTGIS_REPO" "$POSTGIS_REF"
sync_repo pgroonga "$PGROONGA_REPO" "$PGROONGA_REF" 1
sync_repo pgvector "$PGVECTOR_REPO" "$PGVECTOR_REF"
sync_repo vectorchord "$VECTORCHORD_REPO" "$VECTORCHORD_REF"
sync_repo vectorchord-bm25 "$VECTORCHORD_BM25_REPO" "$VECTORCHORD_BM25_REF"
sync_repo pg_tokenizer.rs "$PG_TOKENIZER_REPO" "$PG_TOKENIZER_REF"
