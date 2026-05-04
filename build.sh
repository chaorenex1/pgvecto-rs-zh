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
Usage: bash build.sh [fetch|build|all|clean] [--no-cache]

  fetch     Download PostgreSQL source and clone all extension sources.
  build     Build the Docker image from local sources/.
  all       Fetch sources and then build (default).
  clean     Remove local minir-pg images for the selected PG major.
EOF
}

ACTION=all
NO_CACHE=0
IMAGE_NAME=minir-pg
for arg in "$@"; do
  case "$arg" in
    fetch|build|all|clean)
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

if [[ "$ACTION" == "clean" ]]; then
  log "Removing local image tags for ${IMAGE_NAME}"

  image_tags=(
    "${IMAGE_NAME}:pg${PG_MAJOR}"
    "${IMAGE_NAME}:latest"
  )

  existing_tags=()
  for tag in "${image_tags[@]}"; do
    if docker image inspect "$tag" >/dev/null 2>&1; then
      existing_tags+=("$tag")
    fi
  done

  if [[ "${#existing_tags[@]}" -eq 0 ]]; then
    echo "No local image tags found for ${IMAGE_NAME}"
  else
    docker image rm -f "${existing_tags[@]}"
  fi
fi

if [[ "$ACTION" == "build" || "$ACTION" == "all" ]]; then
  log "Building image ${IMAGE_NAME}:pg${PG_MAJOR}"

  build_args=(
    --build-arg "PG_MAJOR=${PG_MAJOR}"
    --build-arg "PG_VERSION=${PG_VERSION}"
    -t "${IMAGE_NAME}:pg${PG_MAJOR}"
    -t "${IMAGE_NAME}:latest"
  )

  if [[ "$NO_CACHE" -eq 1 ]]; then
    build_args+=(--no-cache)
  fi

  docker build "${build_args[@]}" .
fi
