#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

SOURCES_DIR=${1:?source directory is required}
PG_VERSION=${PG_VERSION:?PG_VERSION must be set}
PG_TARBALL="${SOURCES_DIR}/postgresql-${PG_VERSION}.tar.bz2"
BUILD_ROOT=/tmp/postgresql-build

if [[ ! -f "$PG_TARBALL" ]]; then
  echo "missing PostgreSQL source tarball: $PG_TARBALL"
  exit 1
fi

log_step "Preparing PostgreSQL ${PG_VERSION} source"
rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT"
tar -xjf "$PG_TARBALL" -C "$BUILD_ROOT"
cd "$BUILD_ROOT/postgresql-${PG_VERSION}"

configure_args=(
  --prefix=/usr/local/pgsql
  --with-icu
  --with-liburing
  --with-lz4
  --with-openssl
)

log_step "Configuring PostgreSQL ${PG_VERSION}"
./configure "${configure_args[@]}"

log_step "Building PostgreSQL ${PG_VERSION}"
make -j"$MAKE_JOBS"

log_step "Installing PostgreSQL ${PG_VERSION}"
make install
make -C contrib install
