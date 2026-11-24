#!/usr/bin/env bash
# Shared module paths and public-address validation.
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_ADDRESS=g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5
ONYX_RPC=https://rpc.onyx.testnets.gno.land:443
ONYX_WEB=https://onyx.testnets.gno.land
ONYX_CHAIN=onyx-1
OWNER_KEY=erratabank-owner
READER_KEY=erratabank-reader
PACKAGES=(gno/p/errata gno/r/erratabank gno/r/erratademo)

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

require_gnoroot() {
  if [[ -z ${GNOROOT:-} || ! -d "$GNOROOT/gnovm/stdlibs/strconv" ]]; then
    die 'GNOROOT must point to the Gno v1.8.0 source directory.
Download the v1.8.0 source tarball from https://github.com/gnolang/gno/archive/refs/tags/v1.8.0.tar.gz.
Extract it to ~/gno-1.8.0, then run the following command.
  export GNOROOT=~/gno-1.8.0'
  fi
}

module_path() {
  sed -nE 's/^module = "([^"]+)"$/\1/p' "$PROJECT_ROOT/$1/gnomod.toml"
}

# Check the lowercase g HRP, 20-byte payload, and Bech32 checksum.
valid_address() {
  local addr=$1 alphabet=qpzry9x8gf2tvdw0s3jn54khce6mua7l
  [[ $addr =~ ^g1[qpzry9x8gf2tvdw0s3jn54khce6mua7l]{38}$ ]] || return 1
  local i j char index top
  local checksum=1
  local -a values=(3 0 7)
  local -a generators=(0x3b6a57b2 0x26508e6d 0x1ea119fa 0x3d4233dd 0x2a1462b3)
  for ((i=2; i<${#addr}; i++)); do
    char=${addr:i:1}
    index=${alphabet%%"$char"*}
    values+=("${#index}")
  done
  for index in "${values[@]}"; do
    top=$((checksum >> 25))
    checksum=$(((checksum & 0x1ffffff) << 5 ^ index))
    for ((j=0; j<5; j++)); do
      if (( (top >> j) & 1 )); then
        checksum=$((checksum ^ generators[j]))
      fi
    done
  done
  ((checksum == 1))
}

load_modules() {
  ERRATA_PATH=$(module_path gno/p/errata)
  BANK_PATH=$(module_path gno/r/erratabank)
  DEMO_PATH=$(module_path gno/r/erratademo)
  NAMESPACE=${BANK_PATH#gno.land/r/}
  NAMESPACE=${NAMESPACE%%/*}
  if ! valid_address "$NAMESPACE" ||
    [[ $ERRATA_PATH != "gno.land/p/$NAMESPACE/errata/v0" ||
       $BANK_PATH != "gno.land/r/$NAMESPACE/erratabank/v0" ||
       $DEMO_PATH != "gno.land/r/$NAMESPACE/erratademo/v0" ]]; then
    die 'The three gnomod.toml files must share a valid address namespace.'
  fi
}

require_onyx_namespace() {
  load_modules
  [[ $NAMESPACE != "$DEV_ADDRESS" ]] ||
    die 'Run scripts/set-namespace.sh with your public owner address first.'
  command -v gnokey >/dev/null || die 'Install gnokey v1.8.0 and add it to PATH.'
}

web_url() {
  printf '%s/%s' "$ONYX_WEB" "${1#gno.land/}"
  if [[ -n ${2:-} ]]; then
    printf ':%s' "$2"
  fi
  printf '\n'
}

terminal_only() {
  [[ -t 0 && -t 1 ]] || die 'Run this signing script in your own Terminal.'
}

key_address() {
  gnokey list | awk -v key="$1" '$2 == key && $5 == "addr:" { print $6 }'
}

require_funded() {
  local addr=$1 balance
  balance=$(gnokey query -remote "$ONYX_RPC" "bank/balances/$addr") ||
    die "Unable to verify Onyx funds for $addr."
  [[ $balance =~ (^|[^0-9])[1-9][0-9]*ugnot ]] ||
    die "Fund $addr on Onyx first at https://faucet.gno.land."
  printf 'Onyx balance for %s\n%s\n' "$addr" "$balance"
}

pause_step() {
  printf '\n%s\nPress Enter to continue, or Ctrl-C to stop. ' "$1"
  IFS= read -r
}
