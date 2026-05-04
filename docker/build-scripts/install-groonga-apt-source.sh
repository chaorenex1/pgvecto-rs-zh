#!/usr/bin/env bash
set -euo pipefail

codename=$(. /etc/os-release && printf '%s' "${VERSION_CODENAME:?missing VERSION_CODENAME}")
package="groonga-apt-source-latest-${codename}.deb"
url="https://packages.groonga.org/ubuntu/${package}"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

curl --fail --location --silent --show-error \
  --output "${tmp_dir}/${package}" \
  "$url"

apt-get install -y --no-install-recommends "${tmp_dir}/${package}"
