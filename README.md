# Erratabank

Publish an on-chain errata page that credits the first finder and can pay a reward automatically.

Errata for books and technical material often end up scattered across issue trackers, emails, and personal sites. That makes it hard to settle who found a mistake first or take credit for a correction from one publication to another. Erratabank gives authors, course makers, and documentation maintainers a public review queue. Every reader gets a finder page with a history of accepted corrections across books. Knuth's reward checks inspired the optional rewards.

Erratabank was started on 23 Nov 2026 for the Gnome Tavern hackathon. Nothing existed before that date.

## Onyx deployment

| Component | Onyx |
| --- | --- |
| Realm | [Erratabank](https://onyx.testnets.gno.land/r/g132vz03ycpaagtef4jmxjakstkppgyc5wn3r807/erratabank/v0) |
| Package | [errata](https://onyx.testnets.gno.land/p/g132vz03ycpaagtef4jmxjakstkppgyc5wn3r807/errata/v0) |
| Demo realm | [Erratabank Quickstart](https://onyx.testnets.gno.land/r/g132vz03ycpaagtef4jmxjakstkppgyc5wn3r807/erratademo/v0) |

The chain ID is `onyx-1` and its RPC endpoint is `https://rpc.onyx.testnets.gno.land:443`. The hackathon submission closes on 18 Dec 2026 at 01:00 UTC (02:00 Africa/Lagos). It requires a working testnet deployment, a public repository, a README, and a demo video. [Gnome Tavern hackathon](https://dorahacks.io/hackathon/gnome-tavern/detail)

## How it works

1. A maintainer calls `CreateBook` with a title, edition, source link, and reward in ugnot. The caller owns that book. Creation can include an initial send, and anyone can add escrow later with `FundBook`.
2. A reader uses `Submit` to give the location, describe the error, and suggest a correction. The chain records its block height. Increasing submission IDs establish the order within a block.
3. The owner reviews reports in submission order. `Accept` credits the finder. `Reject` can record a short reason. Use `MarkDuplicate` to link a pending report to an earlier accepted report in the same book. Accept the original first. A duplicate gets no credit or payout. The owner judges whether reports describe the same error.
4. When a book carries a reward and has enough escrow, `Accept` pays the full reward in the same transaction. With reward zero or insufficient escrow, acceptance still grants credit and records `Paid=0`. Later funding applies to future acceptances only. Unpaid credits have no automatic retroactive payout.
5. The owner can withdraw unused escrow and close or reopen submissions. Closing a book leaves its existing reports available for review. Book ownership stays with the creating caller.

One GNOT equals 1,000,000 ugnot. The book page displays the reward and available escrow. The finder page displays the accepted reports and exactly how much the realm paid in total. Chain fees and storage deposits are separate from book escrow.

## Use as an author or reader

Open the Erratabank realm in gnoweb and choose **Actions** to find the Adena call forms and matching `gnokey` commands.

- **Authors** use `CreateBook`, then open the book link on the home page. Use the **Pending** list for report IDs and review the earliest valid report first. Use `FundBook` with a positive ugnot send to top up rewards, `SetBookOpen` to control intake, and `Withdraw` to recover unused escrow.
- **Readers** open the book to check accepted and pending reports. Use `Submit` with the book ID, a precise location, and the proposed fix. Follow the finder link on an accepted report to see your public account page.

For example, after deployment, submit to book 1 with a funded reader key. Replace `YOUR_PUBLIC_G1_ADDRESS` with the owner namespace and adjust the book ID.

```bash
owner_addr='YOUR_PUBLIC_G1_ADDRESS'
gnokey maketx call \
  -pkgpath "gno.land/r/$owner_addr/erratabank/v0" -func Submit \
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
    "gno.land/r/<addr>/erratabank/v0"
)

func Render(path string) string {
    entries := erratabank.AcceptedEntries(1)
    return "# My documentation\n\n" + errata.RenderSection("Errata", entries)
}
```

For larger lists, use `AcceptedEntriesPage(bookID, offset, limit)`. The Quickstart demo shows a documentation article with an intentional error and a live errata section. The demo deployer can connect it to a book once with `SetBook`.

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

To run an individual suite, enter one of `gno/p/errata`, `gno/r/erratabank`, or `gno/r/erratademo` and run `gno fmt -diff ./...`, `gno lint ./...`, and `gno test ./...`. Run `gno test -run '_filetest.gno' .` in `gno/r/erratabank` for the escrow filetests alone.

If the release binaries still cannot resolve dependencies, build the tools from the extracted source with Go 1.25 or later.

```bash
(cd "$GNOROOT" && GOBIN="$HOME/.gno/bin" make install)
scripts/test.sh
```

Start a loopback-only chain with all three modules using the original development namespace.

```bash
gnodev local -home '' -unsafe-api=false \
  -add-account g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5 \
  ./gno/p/errata ./gno/r/erratabank ./gno/r/erratademo
```

The `-home ''` flag skips the local keybase. The example address is public and belongs only to this local walkthrough. Open the [Erratabank home](http://localhost:8888/r/g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5/erratabank/v0) and [Quickstart realm](http://localhost:8888/r/g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5/erratademo/v0). The local chain ID is `dev` and its RPC endpoint is `http://localhost:26657`. [Gno installation](https://docs.gno.land/builders/install), [gnodev reference](https://docs.gno.land/resources/gnodev)

## Set up your Onyx keys

1. Install the pinned tools using the command above.
2. In your own Terminal, create separate owner and reader keys.

   ```bash
   gnokey add erratabank-owner
   gnokey add erratabank-reader
   ```

   Write each 24-word mnemonic down offline. **Never share your mnemonic.** Keep mnemonics, passwords, private keys, and keybase files out of Codex, chat, and project files.
3. Run `gnokey list` and copy the two public `g1…` addresses. If sharing setup information with Codex, provide only the public owner address.
4. Fund both public addresses. Select the current testnet and confirm it is Onyx. [Testnet faucet](https://faucet.gno.land)
5. Confirm a positive Onyx balance for each address.

   ```bash
   owner_addr='YOUR_PUBLIC_OWNER_G1_ADDRESS'
   reader_addr='YOUR_PUBLIC_READER_G1_ADDRESS'
   gnokey query -remote https://rpc.onyx.testnets.gno.land:443 "bank/balances/$owner_addr"
   gnokey query -remote https://rpc.onyx.testnets.gno.land:443 "bank/balances/$reader_addr"
   ```

## Deploy and record the demo

After funding, run these commands in your own Terminal from the project directory.

```bash
scripts/set-namespace.sh "$owner_addr"
scripts/test.sh
scripts/deploy-onyx.sh
```

`set-namespace.sh` validates the public address, rewrites the module paths and imports in a staging copy, and tests all three modules before applying the changes. `deploy-onyx.sh` checks the local owner key's public address and its Onyx balance, then skips packages already live. For the next package, open the printed GPAS link. Type `submit` only if no submission is awaiting approval. The script simulates the deployment, shows the estimated gas, and pauses before the signed transaction. After broadcasting, it prints the same GPAS link and exits.

Rerun the deploy script after each package goes live. The order is `errata`, `erratabank`, then `erratademo`. The `erratabank` realm can only be approved after the `errata` package is live because the realm imports it. If the chain requests a CLA, use the Onyx CLA page. You can set `MAX_DEPLOY_DEPOSIT` or `MAX_CALL_DEPOSIT` to a positive ugnot cap if simulation indicates a larger storage deposit. [Package approval status](https://gpas.latest.testnets.gno.land), [Onyx CLA](https://onyx.testnets.gno.land/r/sys/cla), [Storage deposits](https://docs.gno.land/resources/storage-deposit)

Once all three packages are live, query an existing book or use the rehearsal script on a fresh deployment with an unlinked guide. The guide can be linked once.

```bash
scripts/query-onyx.sh 1
```

`query-onyx.sh` uses read-only `qrender` and `qeval`. The [recording script](docs/DEMO_SCRIPT.md) describes the expanded rehearsal in `scripts/demo-onyx.sh`.

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
