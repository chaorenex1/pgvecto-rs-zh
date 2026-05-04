#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$ROOT_DIR"

log() {
  printf '\n==> %s\n' "$*"
}

require_command() {
  local name=$1
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "$name is required"
    exit 1
  fi
}

require_command docker
require_command git

set -a
source docker/versions.env
set +a

usage() {
  cat <<EOF
Usage: bash build.sh [fetch|build|all] [--no-cache]

  fetch     Download PostgreSQL source and clone all extension sources.
  build     Build the Docker image from local sources/.
  all       Fetch sources and then build (default).
EOF
}

ACTION=all
NO_CACHE=0
for arg in "$@"; do
  case "$arg" in
    fetch|build|all)
      ACTION="$arg"
      ;;
    --no-cache)
      NO_CACHE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      usage
      exit 1
      ;;
  esac
done

if [[ "$ACTION" == "fetch" || "$ACTION" == "all" ]]; then
  log "Fetching PostgreSQL ${PG_VERSION} and extension sources"
  bash docker/fetch-sources.sh
fi

if [[ "$ACTION" == "build" || "$ACTION" == "all" ]]; then
  log "Building image pgvecto-rs-zh:pg${PG_MAJOR}"

  build_args=(
    --build-arg "PG_MAJOR=${PG_MAJOR}"
    --build-arg "PG_VERSION=${PG_VERSION}"
    -t "pgvecto-rs-zh:pg${PG_MAJOR}"
    -t "pgvecto-rs-zh:latest"
  )

  if [[ "$NO_CACHE" -eq 1 ]]; then
    build_args+=(--no-cache)
  fi

  docker build "${build_args[@]}" .
fi
