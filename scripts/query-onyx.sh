#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[[ $# -le 2 ]] || die "Usage: $0 [book-id [finder-g1-address]]"
require_onyx_namespace
book_id=${1:-}
finder=${2:-}
if [[ -n $book_id && ! $book_id =~ ^[1-9][0-9]*$ ]]; then
  die 'Book ID must be a positive integer.'
fi
if [[ -n $finder ]] && ! valid_address "$finder"; then
  die 'Expected a valid lowercase finder g1 address.'
fi

qrender() {
  web_url "$1" "$2"
  gnokey query -remote "$ONYX_RPC" -data "$1:$2" vm/qrender
}

qrender "$BANK_PATH" ""
qrender "$DEMO_PATH" ""
if [[ -n $book_id ]]; then
  qrender "$BANK_PATH" "book/$book_id"
  gnokey query -remote "$ONYX_RPC" -data "$BANK_PATH.GetBook($book_id)" vm/qeval
fi
if [[ -n $finder ]]; then
  qrender "$BANK_PATH" "finder/$finder"
  qrender "$BANK_PATH" "finder/$finder/unpaid"
  gnokey query -remote "$ONYX_RPC" -data "$BANK_PATH.FinderStats(address(\"$finder\"))" vm/qeval
fi
