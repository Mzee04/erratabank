#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_gnoroot
cd "$PROJECT_ROOT"
gno mod download -remote-overrides "gno.land=$ONYX_RPC"
for package_dir in "${PACKAGES[@]}"; do
  printf '\nChecking %s\n' "$package_dir"
  (
    cd "$package_dir"
    gno fmt -diff ./...
    gno lint ./...
    gno test ./...
  )
done
