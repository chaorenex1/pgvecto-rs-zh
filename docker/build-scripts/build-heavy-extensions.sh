#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

SOURCES_DIR=${1:?source directory is required}
PG_PREFIX=${PG_PREFIX:-/usr/local/pgsql18}
export PATH="${PG_PREFIX}/bin:$PATH"
export PG_CONFIG="${PG_PREFIX}/bin/pg_config"

build_postgis() {
  local dir="${SOURCES_DIR}/postgis"
  require_dir "$dir"

  log_step "Building PostGIS"
  cd "$dir"
  ./autogen.sh
  ./configure --with-pgconfig="$PG_CONFIG"
  make -j"$MAKE_JOBS"
  make install
}

build_pgroonga() {
  local dir="${SOURCES_DIR}/pgroonga"
  require_dir "$dir"

  log_step "Building PGroonga"
  cd "$dir"
  meson setup build --wipe \
    --prefix="$PG_PREFIX" \
    -Dinstall_to_postgresql=true \
    -Dmessage_pack=enabled \
    -Dpg_config="$PG_CONFIG" \
    -Dtest=false \
    -Dxxhash=enabled
  meson compile -C build -j"$MAKE_JOBS"
  meson install -C build
}

build_postgis
build_pgroonga
