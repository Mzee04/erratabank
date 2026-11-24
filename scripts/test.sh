#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_gnoroot
cd "$PROJECT_ROOT"
gno mod download -remote-overrides "gno.land=$ONYX_RPC"
packages=(gno/p/errata gno/r/erratabank gno/r/erratabank/v1 gno/r/erratademo gno/r/erratademo/v1)
for package_dir in "${packages[@]}"; do
  printf '\nChecking %s\n' "$package_dir"
  (
    cd "$package_dir"
    gno fmt -diff .
    gno lint .
    gno test -v .
  )
done
