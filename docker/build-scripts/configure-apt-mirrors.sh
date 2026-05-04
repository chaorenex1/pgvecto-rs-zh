#!/usr/bin/env bash
set -euo pipefail

echo "INFO: Attempting to switch Ubuntu/Debian APT sources to mirrors.aliyun.com..."
if [[ -f /etc/apt/sources.list.d/ubuntu.sources ]]; then
  echo "INFO: Modifying /etc/apt/sources.list.d/ubuntu.sources"
  sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list.d/ubuntu.sources
  sed -i 's|http://security.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list.d/ubuntu.sources
elif [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
  echo "INFO: Modifying /etc/apt/sources.list.d/debian.sources"
  sed -i 's|http://deb.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources
  sed -i 's|http://security.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources
elif [[ -f /etc/apt/sources.list ]]; then
  echo "INFO: Modifying /etc/apt/sources.list"
  sed -i 's|http://deb.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list
  sed -i 's|http://security.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list
  sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list
  sed -i 's|http://security.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list
else
  echo "WARNING: Standard Debian/Ubuntu APT source files not found in expected locations."
fi

echo "INFO: Attempting to switch PGDG APT source to mirrors.aliyun.com..."
find /etc/apt/sources.list* -type f \( -name '*.list' -o -name '*.sources' \) -exec \
  sed -i 's|http://apt.postgresql.org/pub/repos/apt|http://mirrors.aliyun.com/postgresql/repos/apt|g' {} + \
  || echo "WARNING: PGDG APT source replacement did not find a typical source file or encountered an error. Proceeding..."
