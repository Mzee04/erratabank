#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[[ $# -eq 1 ]] || die "Usage: $0 <public-owner-g1-address>"
new_address=$1
valid_address "$new_address" || die 'Expected a valid lowercase g1 address.'
[[ $new_address != "$DEV_ADDRESS" ]] || die 'The example address is reserved for local development.'
require_gnoroot
command -v gno >/dev/null || die 'Install gno v1.8.0 and add it to PATH.'
load_modules

# Verify the v1 rewrite in a temporary workspace before touching the project files.
stage=$(mktemp -d "${TMPDIR:-/tmp}/erratabank-namespace.XXXXXXXX")
trap 'rm -rf "$stage"' EXIT
stage=$(cd "$stage" && pwd -P)
cp -R "$PROJECT_ROOT/gno" "$PROJECT_ROOT/gnowork.toml" "$stage/"
files=()
while IFS= read -r -d '' file; do
  files+=("${file#"$stage"/}")
  sed -E "s#(gno[.]land/r/)$NAMESPACE/(erratabank|erratademo)/v1#\1$new_address/\2/v1#g" "$file" > "$file.rewrite"
  mv "$file.rewrite" "$file"
done < <(find "$stage/${V1_PACKAGES[0]}" "$stage/${V1_PACKAGES[1]}" \
  -type f \( -name '*.gno' -o -name gnomod.toml \) -print0)

(
  cd "$stage"
  gno mod download -remote-overrides "gno.land=$ONYX_RPC"
)
for package_dir in "${V1_PACKAGES[@]}"; do
  (cd "$stage/$package_dir" && gno test .)
done

for file in "${files[@]}"; do
  if ! cmp -s "$stage/$file" "$PROJECT_ROOT/$file"; then
    cp "$stage/$file" "$PROJECT_ROOT/$file"
  fi
done
printf 'Validated v1 realm namespace %s with the existing errata/v0 library.\n' "$new_address"
