#!/usr/bin/env bash
set -euo pipefail

MAKE_JOBS=${MAKE_JOBS:-$(nproc)}

log_step() {
  printf '\n==> %s\n' "$*"
}

require_dir() {
  local dir=$1
  if [[ ! -d "$dir" ]]; then
    echo "missing source directory: $dir"
    exit 1
  fi
}

run_pgxs_make() {
  local dir=$1
  shift
  require_dir "$dir"
  make -C "$dir" PG_CONFIG="$PG_CONFIG" -j"$MAKE_JOBS" "$@"
}
