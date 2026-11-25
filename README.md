# Erratabank

Publish an on-chain errata page where maintainers review corrections, credit finders, and can fund rewards.

Errata for books and technical material often end up scattered across issue trackers, emails, and personal sites. That makes it hard to settle who found a mistake first or take credit for a correction from one publication to another. Erratabank gives authors, course makers, and documentation maintainers a public review queue. Every reader gets a finder page with a history of accepted corrections across books. Knuth's reward checks inspired the optional rewards.

Erratabank was started on 23 Nov 2026 for the Gnome Tavern hackathon. Nothing existed before that date.

## Onyx deployment

Erratabank v1 and Quickstart v1 are live on Onyx. The table and recorded transactions below preserve the v0 deployment history.

| Component | Onyx |
| --- | --- |
| Realm | [Erratabank](https://onyx.testnets.gno.land/r/g132vz03ycpaagtef4jmxjakstkppgyc5wn3r807/erratabank/v0) |
| Package | [errata](https://onyx.testnets.gno.land/p/g132vz03ycpaagtef4jmxjakstkppgyc5wn3r807/errata/v0) |
| Demo realm | [Erratabank Quickstart](https://onyx.testnets.gno.land/r/g132vz03ycpaagtef4jmxjakstkppgyc5wn3r807/erratademo/v0) |

The chain ID is `onyx-1` and its RPC endpoint is `https://rpc.onyx.testnets.gno.land:443`. The hackathon submission closes on 18 Dec 2026 at 01:00 UTC (02:00 Africa/Lagos). It requires a working testnet deployment, a public repository, a README, and a demo video. [Gnome Tavern hackathon](https://dorahacks.io/hackathon/gnome-tavern/detail)

## How v1 works

1. A maintainer calls `CreateBook` with a title, edition, source link, and reward in ugnot. The caller owns that book. An initial send and later sends from the owner count as owner funds. Other callers use `FundBook` to add locked sponsor funds.
2. A reader uses `Submit` to give the location, describe the error, and suggest a correction. Reports are public and permanent on-chain. The chain records the block height and assigns a submission ID.
3. The owner decides what to accept. An earlier pending report at the same trimmed, case-sensitive location must be resolved before a later one can be accepted. `MarkDuplicate` can link to an earlier pending or accepted report in the same book.
4. An accepted report from a different address on a book with a positive reward qualifies for credit and payment. Self-owned and zero-reward reports appear separately as unpaid credits. The finder page shows amounts paid and owed.
5. If funds fall short, the reward is recorded as owed. Funding pays rewards in acceptance order once the oldest owed reward is covered. Sponsor balances are used in address order before owner deposits. Large queues or rewards funded by many sponsors can take multiple calls to `SettleOwed`, which anyone can use to continue payouts.
6. The owner can withdraw only their own deposits after owed rewards settle. Closing a book pauses new submissions and acceptances. The owner can still fund existing debts and reject or mark reports as duplicates. Once debts settle on a closed book, each sponsor can claim its remaining funds with `RefundSponsor`. The owner can reopen the book after remaining sponsor balances are cleared.

One GNOT equals 1,000,000 ugnot. The book page shows owner funds, locked sponsor funds, and amounts owed. A reward depends on owner acceptance and funding. Chain fees and storage deposits are separate from these funds.

## Review findings addressed

- Separated owner and sponsor funds, directed later deposits to owed rewards in acceptance order, and gave sponsors a refund path on closed books.
- Enforced first-finder order per location and separated unpaid credits from reward-eligible credits.
- Assigned IDs from dedicated counters and capped public list queries at 50. Integrations use `AcceptedEntriesPage`.
- Kept rejected correction text in **All reports** and added the public, permanent submission notice.

## Use as an author or reader

Open the Erratabank realm in gnoweb and choose **Actions** to find the Adena call forms and matching `gnokey` commands.

- **Authors** use `CreateBook`, then open the book link on the home page. Use the **Pending** list for report IDs and review the earliest report at each location first. Use `FundBook` with a positive ugnot send to top up rewards, `SetBookOpen` to control intake, and `Withdraw` to recover unreserved owner deposits.
- **Readers** open the book to check accepted and pending reports. Use `Submit` with the book ID, a precise location, and the proposed fix. Follow the finder link on an accepted report to see your public account page. Open **All reports** to read rejected corrections.
- **Sponsors** use `FundBook` to add locked funds for accepted finders. Use `SponsorBalance` to check your remaining contribution and `RefundSponsor` to claim it once the owner closes the book and owed rewards settle.

For example, after deployment, submit to book 1 with a funded reader key. Replace `YOUR_PUBLIC_G1_ADDRESS` with the owner namespace and adjust the book ID.

```bash
owner_addr='YOUR_PUBLIC_G1_ADDRESS'
gnokey maketx call \
  -pkgpath "gno.land/r/$owner_addr/erratabank/v1" -func Submit \
  -args 1 -args 'p. 42, line 3' -args 'Says O(n log n). The loop is O(n^2).' \
  -gas-fee 20000ugnot -gas-wanted 20000000 -max-deposit 5000000ugnot \
  -chainid onyx-1 -remote https://rpc.onyx.testnets.gno.land:443 \
  erratabank-reader
```

Supply `-send <amount>ugnot` on `FundBook` and on `CreateBook` when escrowing funds. The limits are 120 characters for title, edition, and location, 1,000 for correction text, and 300 for links and optional review notes.

## Embed an errata section in another realm

Import the pure `errata` package to render your own entries. For accepted reports from Erratabank, import its realm as well. Substitute the deployed namespace in both imports.

```go
import (
    "gno.land/p/<addr>/errata/v0"
    "gno.land/r/<addr>/erratabank/v1"
)

func Render(path string) string {
    entries := erratabank.AcceptedEntriesPage(1, 0, 20)
    return "# My documentation\n\n" + errata.RenderSection("Errata", entries)
}
```

Use `AcceptedEntriesPage(bookID, offset, limit)` to page through accepted reports. The limit is capped at 50. `AcceptedEntries` returns the first 50. The Quickstart demo shows a documentation article with an intentional error and a live errata section. The demo deployer can connect it to a book once with `SetBook`.

## Local development

Install the Gno **v1.8.0** binaries in `~/.gno/bin` and download the matching source tarball for the standard library.

```bash
curl -fsSL https://raw.githubusercontent.com/gnolang/gno/master/misc/install.sh | sh -s -- --version v1.8.0
export PATH="$HOME/.gno/bin:$PATH"
curl -fL https://github.com/gnolang/gno/archive/refs/tags/v1.8.0.tar.gz -o "$HOME/gno-v1.8.0.tar.gz"
tar -xzf "$HOME/gno-v1.8.0.tar.gz" -C "$HOME"
export GNOROOT=~/gno-1.8.0
gno version && gnokey version && gnodev --help
```

Fetch the public package dependencies from Onyx and run the format check, lint, and tests for all three modules.

```bash
scripts/test.sh
```

To run an individual suite, enter its module directory and run `gno fmt -diff .`, `gno lint .`, and `gno test .`. The test script covers the shared v0 library and both versions of each realm. Run `gno test -run '_filetest.gno' .` in `gno/r/erratabank/v1` for the v1 balance filetests.

If the release binaries still cannot resolve dependencies, build the tools from the extracted source with Go 1.25 or later.

```bash
(cd "$GNOROOT" && GOBIN="$HOME/.gno/bin" make install)
scripts/test.sh
```

Start a loopback-only chain with the shared library and both v1 realms.

```bash
gnodev local -home '' -unsafe-api=false \
  -add-account g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5 \
  ./gno/p/errata ./gno/r/erratabank/v1 ./gno/r/erratademo/v1
```

The `-home ''` flag skips the local keybase. The example account belongs only to this local walkthrough. Open the [v1 Erratabank home](http://localhost:8888/r/g132vz03ycpaagtef4jmxjakstkppgyc5wn3r807/erratabank/v1) and [v1 Quickstart realm](http://localhost:8888/r/g132vz03ycpaagtef4jmxjakstkppgyc5wn3r807/erratademo/v1). The local chain ID is `dev` and its RPC endpoint is `http://localhost:26657`. [Gno installation](https://docs.gno.land/builders/install), [gnodev reference](https://docs.gno.land/resources/gnodev)

## Set up your Onyx keys

1. Install the pinned tools using the command above.
2. In your own Terminal, create separate keys for any missing v1 demo roles.

   ```bash
   gnokey add erratabank-owner
   gnokey add erratabank-sponsor
   gnokey add erratabank-reader
   gnokey add erratabank-reader-2
   ```

   Write each 24-word mnemonic down offline. **Never share your mnemonic.** Keep mnemonics, passwords, private keys, and keybase files out of Codex, chat, and project files.
3. Run `gnokey list` to find the public `g1…` addresses for the four roles. If sharing setup information with Codex, provide only the public owner address.
4. Fund the four public addresses. Select the current testnet and confirm it is Onyx. [Testnet faucet](https://faucet.gno.land)
5. Confirm each role’s balance covers transaction fees and storage deposits. The sponsor also needs 2.1 GNOT for its two deposits, and the owner needs 0.25 GNOT for the book deposit.

   ```bash
   addr='PUBLIC_G1_ADDRESS'
   gnokey query -remote https://rpc.onyx.testnets.gno.land:443 "bank/balances/$addr"
   ```

## Deploy and record the demo

The v1 realms need separate GPAS approval in this order. The published `p/g132vz03ycpaagtef4jmxjakstkppgyc5wn3r807/errata/v0` library is reused.

1. Submit `gno.land/r/g132vz03ycpaagtef4jmxjakstkppgyc5wn3r807/erratabank/v1` and wait for GPAS activation.
2. Submit `gno.land/r/g132vz03ycpaagtef4jmxjakstkppgyc5wn3r807/erratademo/v1` after the bank is live, then wait for its activation.

From the project directory, run the tests. Use `set-namespace.sh "$owner_addr"` only if you will deploy the v1 realms from a different owner address. It tests and rewrites only the two v1 realms, including their imports and tests.

```bash
scripts/test.sh
```

Once signing is authorized, run `scripts/deploy-onyx.sh --simulate-only` to size the next package submission. The simulation requires the owner to sign and exits before broadcast.

Once broadcast is authorized, run `scripts/deploy-onyx.sh` in your Terminal. It checks the owner address and balance, skips live packages, and stops on a pending submission. Open the printed GPAS link and type `submit` only if the package has no pending submission. The script simulates the next package, pauses before broadcast, and exits after broadcasting that one package. Rerun it after the bank is live to submit the demo. Use `MAX_DEPLOY_DEPOSIT` or `MAX_CALL_DEPOSIT` if simulation calls for a higher storage cap. [Package approval status](https://gpas.latest.testnets.gno.land), [Onyx CLA](https://onyx.testnets.gno.land/r/sys/cla), [Storage deposits](https://docs.gno.land/resources/storage-deposit)

Run `scripts/demo-onyx.sh` only after both v1 realms are live and the guide is unlinked. The live Onyx guide is already linked to book #1, so use `scripts/query-onyx.sh 1` to inspect the completed run. On a fresh deployment, replace the example ID below with the book ID printed by the script.

```bash
scripts/demo-onyx.sh
scripts/query-onyx.sh 1
```

`query-onyx.sh` uses read-only `qrender` and `qeval`. The [v1 recording script](docs/DEMO_SCRIPT.md) follows the actual sponsor, finder, duplicate, top-up, withdrawal, and integration calls.

### Verified Onyx demo, 24 Nov 2026

The owner registered *Erratabank Quickstart* as book #1 with a reward of 1 GNOT per accepted correction and 1 GNOT in escrow. The owner linked the Quickstart guide to book #1. The reader submitted erratum #1 for Section 1, explaining that the guide says to open a fenced code block with two backticks and suggesting three backticks on their own line. The owner accepted it.

`gnokey query vm/qrender` confirmed that the Erratabank index lists book #1 with one accepted report and that both pages display the same correction with a 1 GNOT payout. The book's escrow reached 0 GNOT. The finder balance rose from 9.502 GNOT immediately before acceptance to 10.502 GNOT afterward. [Book #1 and accepted errata](https://onyx.testnets.gno.land/r/g132vz03ycpaagtef4jmxjakstkppgyc5wn3r807/erratabank/v0:book/1) · [Quickstart guide and embedded errata](https://onyx.testnets.gno.land/r/g132vz03ycpaagtef4jmxjakstkppgyc5wn3r807/erratademo/v0)

| Onyx transaction | Block | Hash reported by gnokey |
| --- | ---: | --- |
| `CreateBook` with escrow | 1387454 | `mWTjGLfQhvhAshix8iY5AJiRdY2LH6+bz+k+YDMgnec=` |
| `SetBook` | 1387458 | `+BT4L2QqM+2OvtO4DJCayy5nanKVPLTSCr15mi8sR6E=` |
| `Submit` | 1387461 | `YLGlXst0xuLLpDO7sXzfDv1yW3CIEWFVPJiL7TvRe/U=` |
| `Accept` | 1387466 | `fS4fttabEq39TANxyeC+SO10FenaZ8gMF0NfOX5HYFo=` |

## Security and verification

Crossing methods require `cur.IsCurrent()` and derive caller identity from `cur.Previous().Address()`. The two payable actions require a direct `IsUserCall()` before reading inbound coins and validate positive ugnot sends. Other book and report actions reject attached coins on direct calls. The realm debits escrow and records the review before sending with the realm banker. Readers return copies of book, report, and entry data. The renderers escape user text for its Markdown context, validate finder addresses, and use ordered indexes and 20-row pages. [Realm author security guide](https://docs.gno.land/resources/gno-security-guide), [Effective Gno](https://docs.gno.land/resources/effective-gno)

Formatting, `gno lint ./...`, and `gno test ./...` passed in all three modules using the v1.8.0 release binaries with `GNOROOT` pointing to the matching source release. The dependency cache was populated with read-only Onyx queries. The tests cover payment and withdrawal balances, bad sends, owner permissions, first-finder ordering, review transitions, escaped Markdown, pagination, and cross-realm rendering.

`gnodev` loaded all three modules and served gnoweb at `http://localhost:8888`. The home showed the empty book list and the Actions tab exposed the call forms and CLI commands. A second local run with seeded data showed the accepted correction on both realms, a finder payout of 1 GNOT, a duplicate linked to the original report, 1.5 GNOT of escrow after withdrawal, and a second page of pending reports.

## Author and license

Toyyib Olamilekan

MIT. See [LICENSE](LICENSE).
