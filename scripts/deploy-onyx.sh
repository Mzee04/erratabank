#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[[ $# -eq 0 ]] || die "Usage: $0"
terminal_only
require_onyx_namespace
owner_addr=$(key_address "$OWNER_KEY")
[[ $owner_addr == "$NAMESPACE" ]] ||
  die "Local key $OWNER_KEY must match the namespace $NAMESPACE."
require_funded "$owner_addr"

deposit_cap=${MAX_DEPLOY_DEPOSIT:-10000000ugnot}
[[ $deposit_cap =~ ^[1-9][0-9]*ugnot$ ]] || die 'MAX_DEPLOY_DEPOSIT must be a positive ugnot amount.'

query_files() {
  gnokey query -remote "$ONYX_RPC" -data "$1" vm/qfile
}

deploy() {
  local path=$1 dir=$2 output gas fee suggested_fee approval_url status confirmation
  if query_files "$path" >/dev/null 2>&1; then
    printf '\nAlready present on Onyx\n'
    web_url "$path"
    return
  fi

  approval_url="https://gpas.latest.testnets.gno.land/?path=$path"
  printf '\nCheck Onyx package approval for %s\n%s\n' "$path" "$approval_url"
  if status=$(gnokey query -remote "$ONYX_RPC" -data "$path" vm/qpkgmeta_json 2>/dev/null) &&
    [[ $status =~ \"status\"[[:space:]]*:[[:space:]]*\"inert\" ]]; then
    printf 'This package is already awaiting approval. Rerun once it is live.\n'
    exit 0
  fi
  printf 'Type submit to confirm this package has no submission waiting for approval, or press Enter to stop. '
  if ! IFS= read -r confirmation || [[ $confirmation != submit ]]; then
    printf 'Stopped before simulation. Rerun when you have checked the approval status.\n'
    exit 0
  fi

  local -a args=(-pkgpath "$path" -pkgdir "$PROJECT_ROOT/$dir"
    -max-deposit "$deposit_cap" -chainid "$ONYX_CHAIN" -remote "$ONYX_RPC" -broadcast=true)
  if ! output=$(gnokey maketx addpkg "${args[@]}" -gas-wanted 100000000 -gas-fee 100000ugnot \
    -simulate only "$OWNER_KEY" </dev/tty); then
    printf '%s\n' "$output"
    die 'Simulation failed. Check Onyx funds, package approval, and the storage deposit cap.'
  fi
  printf '%s\n' "$output"
  gas=$(printf '%s\n' "$output" | sed -nE 's/.*suggested, with 5% margin: ([0-9]+).*/\1/p')
  suggested_fee=$(printf '%s\n' "$output" | sed -nE 's/.*gas fee: ([0-9]+)ugnot,.*/\1/p')
  [[ $gas =~ ^[1-9][0-9]*$ ]] || die 'Simulation did not report a suggested gas limit.'
  fee=$(((gas + 999) / 1000))
  if [[ -n $suggested_fee ]] && ((suggested_fee > fee)); then
    fee=$suggested_fee
  fi
  pause_step "Deploy $path with gas limit $gas, fee ${fee}ugnot, and storage cap $deposit_cap."
  gnokey maketx addpkg "${args[@]}" -gas-wanted "$gas" -gas-fee "${fee}ugnot" \
    -simulate test "$OWNER_KEY"

  printf '\nSubmitted %s. Check approval and rerun once it is live.\n%s\n' "$path" "$approval_url"
  exit 0
}

deploy "$ERRATA_PATH" "${PACKAGES[0]}"
deploy "$BANK_PATH" "${PACKAGES[1]}"
deploy "$DEMO_PATH" "${PACKAGES[2]}"
"$PROJECT_ROOT/scripts/query-onyx.sh"
