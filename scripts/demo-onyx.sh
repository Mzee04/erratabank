#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[[ $# -eq 0 ]] || die "Usage: $0"
terminal_only
require_onyx_namespace
owner_addr=$(key_address "$OWNER_KEY")
[[ $owner_addr == "$NAMESPACE" ]] || die "Local key $OWNER_KEY must match $NAMESPACE."
demo_addresses=("$owner_addr")
for key in "$SPONSOR_KEY" "$READER_KEY" "$SECOND_READER_KEY"; do
  addr=$(key_address "$key")
  valid_address "$addr" || die "A funded $key key is required."
  for existing in "${demo_addresses[@]}"; do
    [[ $addr != "$existing" ]] || die 'The owner, sponsor, and readers must use separate demo addresses.'
  done
  demo_addresses+=("$addr")
done
reader_addr=${demo_addresses[2]}
second_reader_addr=${demo_addresses[3]}
for addr in "${demo_addresses[@]}"; do
  require_funded "$addr"
done

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

show_book() {
  web_url "$BANK_PATH" "book/$book_id"
  gnokey query -remote "$ONYX_RPC" -data "$BANK_PATH:book/$book_id" vm/qrender
}

show_finder() {
  web_url "$BANK_PATH" "finder/$1"
  gnokey query -remote "$ONYX_RPC" -data "$BANK_PATH:finder/$1" vm/qrender
}

pause_step 'Owner registers Quickstart with a 1 GNOT reward and deposits 0.25 GNOT of owner funds.'
call "$OWNER_KEY" "$BANK_PATH" CreateBook 250000ugnot \
  'Erratabank Quickstart' 'First edition' "$(web_url "$DEMO_PATH")" 1000000
read_tx_id
book_id=$last_id
show_book

pause_step 'Sponsor deposits 1 GNOT in locked sponsor funds.'
call "$SPONSOR_KEY" "$BANK_PATH" FundBook 1000000ugnot "$book_id"
show_book

location='Section 1. Formatting examples'
pause_step 'Reader submits the first correction at the Markdown example.'
call "$READER_KEY" "$BANK_PATH" Submit '' "$book_id" "$location" \
  'The guide says to use two backticks. Use three backticks on their own line to open a fenced code block.'
read_tx_id
first_id=$last_id
web_url "$BANK_PATH" "erratum/$first_id"

pause_step 'The second reader reports the same location.'
call "$SECOND_READER_KEY" "$BANK_PATH" Submit '' "$book_id" "$location" \
  'The fenced block example needs a third opening backtick.'
read_tx_id
duplicate_id=$last_id
web_url "$BANK_PATH" "book/$book_id/pending"

pause_step 'Owner accepts the first report and the finder receives the 1 GNOT sponsor reward.'
call "$OWNER_KEY" "$BANK_PATH" Accept '' "$first_id" 'Confirmed against the Markdown example.'
show_finder "$reader_addr"
show_book

pause_step 'Owner marks the second report as a duplicate of the first.'
call "$OWNER_KEY" "$BANK_PATH" MarkDuplicate '' "$duplicate_id" "$first_id"
web_url "$BANK_PATH" "erratum/$duplicate_id"

pause_step 'The second reader submits a distinct correction in Section 2.'
call "$SECOND_READER_KEY" "$BANK_PATH" Submit '' "$book_id" 'Section 2. Notes' \
  'The note only asks for expected output. Include observed output as well so maintainers can reproduce a mismatch.'
read_tx_id
owed_id=$last_id
web_url "$BANK_PATH" "erratum/$owed_id"

pause_step 'Owner accepts the Section 2 correction. Available funds fall short, so the finder is owed 1 GNOT.'
call "$OWNER_KEY" "$BANK_PATH" Accept '' "$owed_id" 'Confirmed. Include both observed and expected output.'
show_finder "$second_reader_addr"
show_book

pause_step 'Sponsor tops up 1.1 GNOT. The 1 GNOT debt is paid first, leaving 0.1 GNOT in locked sponsor funds.'
call "$SPONSOR_KEY" "$BANK_PATH" FundBook 1100000ugnot "$book_id"
show_finder "$second_reader_addr"
show_book

pause_step 'Owner withdraws their 0.25 GNOT of unreserved deposits. The 0.1 GNOT sponsor balance stays locked.'
call "$OWNER_KEY" "$BANK_PATH" Withdraw '' "$book_id" 250000
show_book

pause_step 'Deployer links the v1 Quickstart guide to the book so it shows both accepted corrections.'
call "$OWNER_KEY" "$DEMO_PATH" SetBook '' "$book_id"
web_url "$DEMO_PATH"
gnokey query -remote "$ONYX_RPC" -data "$DEMO_PATH:" vm/qrender
