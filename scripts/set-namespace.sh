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

# Verify the rewrite in a temporary workspace before touching the project files.
stage=$(mktemp -d "${TMPDIR:-/tmp}/erratabank-namespace.XXXXXXXX")
trap 'rm -rf "$stage"' EXIT
stage=$(cd "$stage" && pwd -P)
cp -R "$PROJECT_ROOT/gno" "$PROJECT_ROOT/gnowork.toml" "$stage/"
files=()
while IFS= read -r -d '' file; do
  files+=("${file#"$stage"/}")
  sed -E "s|(gno[.]land/[pr]/)$NAMESPACE/|\1$new_address/|g" "$file" > "$file.rewrite"
  mv "$file.rewrite" "$file"
done < <(find "$stage/gno" -type f \( -name '*.gno' -o -name gnomod.toml \) -print0)

(
  cd "$stage"
  gno mod download -remote-overrides "gno.land=$ONYX_RPC"
)
for package_dir in "${PACKAGES[@]}"; do
  (cd "$stage/$package_dir" && gno test ./...)
done

for file in "${files[@]}"; do
  if ! cmp -s "$stage/$file" "$PROJECT_ROOT/$file"; then
    cp "$stage/$file" "$PROJECT_ROOT/$file"
  fi
done
printf 'Validated namespace %s for all three packages.\n' "$new_address"
