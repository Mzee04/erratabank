#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[[ $# -eq 0 ]] || die "Usage: $0"
terminal_only
require_onyx_namespace
owner_addr=$(key_address "$OWNER_KEY")
reader_addr=$(key_address "$READER_KEY")
[[ $owner_addr == "$NAMESPACE" ]] || die "Local key $OWNER_KEY must match $NAMESPACE."
valid_address "$reader_addr" && [[ $reader_addr != "$owner_addr" ]] ||
  die "A separate funded $READER_KEY key is required."
require_funded "$owner_addr"
require_funded "$reader_addr"

# Read the one-time integration setting before creating a demo book.
demo_status=$(gnokey query -remote "$ONYX_RPC" -data "$DEMO_PATH.BookID()" vm/qeval)
[[ $demo_status == *'data: (0 int)'* ]] ||
  die 'This demo realm has already been linked. Use its existing book for the recording.'

deposit_cap=${MAX_CALL_DEPOSIT:-5000000ugnot}
[[ $deposit_cap =~ ^[1-9][0-9]*ugnot$ ]] || die 'MAX_CALL_DEPOSIT must be a positive ugnot amount.'
last_output=''
last_id=''

call() {
  local key=$1 path=$2 fn=$3 payment=$4 arg
  shift 4
  local -a args=(-pkgpath "$path" -func "$fn"
    -gas-wanted 20000000 -gas-fee 40000ugnot -max-deposit "$deposit_cap"
    -chainid "$ONYX_CHAIN" -remote "$ONYX_RPC" -broadcast=true -simulate test)
  if [[ -n $payment ]]; then
    args+=(-send "$payment")
  fi
  for arg in "$@"; do
    args+=(-args "$arg")
  done
  if ! last_output=$(gnokey maketx call "${args[@]}" "$key" </dev/tty); then
    printf '%s\n' "$last_output"
    die "Onyx call $fn failed. Previous successful calls are already on chain."
  fi
  printf '%s\n' "$last_output"
}

read_tx_id() {
  last_id=$(printf '%s\n' "$last_output" | sed -nE 's/^\(([1-9][0-9]*) int\)$/\1/p')
  [[ $last_id =~ ^[1-9][0-9]*$ ]] ||
    die 'The transaction succeeded, but its returned ID could not be read. Inspect the output above.'
}

pause_step 'Owner registers Erratabank Quickstart with a 1 GNOT reward and 3 GNOT of escrow.'
call "$OWNER_KEY" "$BANK_PATH" CreateBook 3000000ugnot \
  'Erratabank Quickstart' 'First edition' "$(web_url "$DEMO_PATH")" 1000000
read_tx_id
book_id=$last_id
web_url "$BANK_PATH" "book/$book_id"

pause_step 'Reader submits the first correction.'
call "$READER_KEY" "$BANK_PATH" Submit '' "$book_id" 'Section 1, first example' \
  'The example says to use two backticks. Use three backticks to open a code block.'
read_tx_id
first_id=$last_id
web_url "$BANK_PATH" "erratum/$first_id"

pause_step 'Reader submits a separate editorial suggestion.'
call "$READER_KEY" "$BANK_PATH" Submit '' "$book_id" 'Section 2, heading' \
  'Rename the heading to Additional Notes.'
read_tx_id
other_id=$last_id
web_url "$BANK_PATH" "erratum/$other_id"

pause_step 'Reader submits a later report for the first correction.'
call "$READER_KEY" "$BANK_PATH" Submit '' "$book_id" 'Section 1, first example' \
  'A fenced block needs three backticks.'
read_tx_id
duplicate_id=$last_id
web_url "$BANK_PATH" "erratum/$duplicate_id"

pause_step 'Owner accepts the first report. Compare the reader balance and the book escrow.'
require_funded "$reader_addr"
call "$OWNER_KEY" "$BANK_PATH" Accept '' "$first_id" 'Confirmed against the Markdown example.'
web_url "$BANK_PATH" "finder/$reader_addr"
web_url "$BANK_PATH" "book/$book_id"
require_funded "$reader_addr"

pause_step 'Owner marks the later report as a duplicate of the first.'
call "$OWNER_KEY" "$BANK_PATH" MarkDuplicate '' "$duplicate_id" "$first_id"
web_url "$BANK_PATH" "erratum/$duplicate_id"

pause_step 'Owner rejects the editorial suggestion.'
call "$OWNER_KEY" "$BANK_PATH" Reject '' "$other_id" 'The current heading is intentional.'
web_url "$BANK_PATH" "erratum/$other_id"

pause_step 'Owner withdraws 0.5 GNOT of unused escrow.'
call "$OWNER_KEY" "$BANK_PATH" Withdraw '' "$book_id" 500000
web_url "$BANK_PATH" "book/$book_id"

pause_step 'Deployer links the Quickstart realm to the book.'
call "$OWNER_KEY" "$DEMO_PATH" SetBook '' "$book_id"
web_url "$DEMO_PATH"
