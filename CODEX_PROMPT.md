# Codex build prompt: Erratabank

Build **Erratabank** locally as a complete, demo-ready Gno.land project: one realm, one importable package and one small demo realm, with tests, scripts and a README. Do not push to GitHub, do not publish, do not deploy to mainnet, do not create accounts, and never ask for, print or commit any secret (mnemonic, password, private key, keybase file).

## Product

Erratabank is an on-chain errata page for books, courses and technical docs that credits the **first** person to find each error. Knuth's reward checks are the inspiration.

- An author or doc maintainer registers a book (title, edition, link) and can optionally escrow a GNOT reward per accepted erratum.
- A reader submits an erratum: location (page/section/URL anchor) plus text (what is wrong, and the suggested fix).
- The book owner reviews each submission: Accept, Reject or MarkDuplicate. Submissions are ordered by block height, so the first valid finder is provable.
- On Accept, the finder is credited and, if the book has a reward and escrow left, paid automatically from the escrow.
- Every book has a public errata page in gnoweb, and every finder has a public "account" page that lists their accepted finds and total earned. No frontend is needed: gnoweb renders `Render(path)` and its Actions tab gives the call forms (Adena) plus the matching `gnokey` command.
- Other realms (a blog, a docs realm) can import the `errata` package to render an "Errata" section in their own `Render`.

Built for the Gnome Tavern Hackathon (https://dorahacks.io/hackathon/gnome-tavern/detail). Open theme. Submissions close 18 Dec 2026 01:00 UTC (02:00 Africa/Lagos). Must be deployed and working on the Gno.land testnet (Onyx) with a genuine Gno component, public repo, README and demo video. Judged on technical quality 40%, user appeal 20%, creativity 20%, docs and demo 20%.

Author display name if needed: Toyyib Olamilekan. No location line.

## Hard rules

- Project name is exactly **Erratabank**. Never use a "Gno" prefix or anything implying an official Gno.land connection (hackathon rule; it can disqualify).
- Languages: Gno for the on-chain code; Bash (or TypeScript/Python only if truly needed) for helper scripts. No paid services.
- Keys live only in the user's local `gnokey` keybase. Never run `gnokey add`, `gnokey recover`, `gnokey export` or anything that prints or reads a mnemonic or private key. Never use `-insecure-password-stdin`. Never write a password, mnemonic or keybase path content into any file.
- The user creates and funds keys himself (steps below). Public `g1…` addresses are fine to use in files.
- Transactions that need a signature (`gnokey maketx addpkg|call`) prompt for the key password. Put them in scripts the **user runs in his own Terminal**. You may run read-only commands yourself (`gnokey list`, `gnokey query …`, `gno test`, `gno lint`, `gnodev`).
- Deploy target is **Onyx testnet only** (`-chainid onyx-1`). Never use `gnoland-1` / `https://rpc.gno.land` (mainnet). Only deploy after the user confirms his key exists and is funded from the faucet.
- `git init` locally and commit as you go is fine. Do **not** add a remote, push, or create a GitHub repo. A human will do that later.
- `.gitignore` must exclude: `.env`, `*.env`, any `*.info`/keybase dirs, `gnokey` home dirs, and local tx files you generate (`*.tx`, `*.sig`).
- README must be honest: Erratabank did not exist before **23 Nov 2026**; the hackathon opened that day. Do not invent an earlier start date or backdated commits.
- Do not invent Gno APIs. Use only what is in the official docs below and in the Gno source you install. If something does not compile, read the installed source / docs and fix it; do not guess.

## Official docs (do not use other URLs as sources)

- Install: https://docs.gno.land/builders/install
- Getting started (local → testnet deploy): https://docs.gno.land/builders/getting-started
- Networks (chain ids, RPC): https://docs.gno.land/resources/gnoland-networks
- `gnomod.toml`: https://docs.gno.land/resources/configuring-gno-projects
- Testing (`gno test`, filetests): https://docs.gno.land/resources/gno-testing
- Interrealm (`cur realm`, `cross`): https://docs.gno.land/resources/gno-interrealm
- Standard libraries (`chain`, `chain/banker`, `chain/runtime`, `testing`): https://docs.gno.land/resources/gno-stdlibs
- Security guide for realm authors (read it before writing payments): https://docs.gno.land/resources/gno-security-guide
- Effective Gno (incl. "Verifying inbound Coin payments"): https://docs.gno.land/resources/effective-gno
- Storage deposit: https://docs.gno.land/resources/storage-deposit
- gnodev: https://docs.gno.land/resources/gnodev
- gnokey usage: https://docs.gno.land/users/interact-with-gnokey
- Namespaces: https://docs.gno.land/resources/users-and-teams
- Reference realm that escrows/sends ugnot (read its code and filetests): https://github.com/gnolang/gno/tree/master/examples/gno.land/r/demo/disperse
- Gno repo / releases: https://github.com/gnolang/gno , https://github.com/gnolang/gno/releases/tag/v1.8.0

## Tooling (verified 23 Nov 2026)

- Latest Gno release: **v1.8.0** (17 Nov 2026). Onyx runs `v1.8.0-rc.1` (same release line). Pin v1.8.0.
- Install (macOS arm64/amd64 supported) into `~/.gno/bin`:

```bash
curl -fsSL https://raw.githubusercontent.com/gnolang/gno/master/misc/install.sh | sh -s -- --version v1.8.0
export PATH="$PATH:$HOME/.gno/bin"
gno version && gnokey version && gnodev --help
```

- If `gno test` cannot resolve standard `gno.land/p/nt/...` imports with the precompiled binaries, fall back to a source build at the same tag (needs Go 1.25+): `git clone https://github.com/gnolang/gno.git && cd gno && git checkout v1.8.0 && make install`, and set `GNOROOT` to that checkout. Record in the README which path you used.
- Format, lint, test from each package dir: `gno fmt ./...`, `gno lint ./...`, `gno test ./...` (filetests only: `gno test -run "_filetest.gno" .`; refresh goldens only when output changes intentionally: `gno test --update-golden-tests .`).
- Local chain with web UI: `gnodev .` (gnoweb at http://localhost:8888, local keys auto-funded, `-chainid dev -remote http://localhost:26657`). To load several package dirs, pass them all on the command line.

### Onyx testnet facts

| Item | Value |
|---|---|
| Chain ID | `onyx-1` |
| RPC | `https://rpc.onyx.testnets.gno.land:443` (alias that always points at the current testnet: `https://rpc.latest.testnets.gno.land:443`) |
| gnoweb | `https://onyx.testnets.gno.land` (also `https://latest.testnets.gno.land`) |
| Faucet | https://faucet.gno.land (pick the current testnet, paste the `g1…` address; rate-limited per address) |
| Package approval status | `https://gpas.latest.testnets.gno.land` (look up the exact package path if a deploy is not enabled after a minute) |
| Gas | `-gas-fee` / `-gas-wanted` must be ≥ 1ugnot per 1000 gas; size with `-simulate only` first |
| Storage deposit | about 100ugnot per byte of code/state, locked on deploy; cap with `-max-deposit` |
| CLA | currently off; if `addpkg` says "has not signed the required CLA", sign at `https://onyx.testnets.gno.land/r/sys/cla` |

Standard packages confirmed present on Onyx: `gno.land/p/nt/avl/v0`, `gno.land/p/nt/ufmt/v0`, `gno.land/p/nt/mux/v0`, `gno.land/p/nt/seqid/v0`, `gno.land/p/nt/markdown/sanitize/v0`.

## Namespace (important)

The docs state username namespaces (`gno.land/r/<name>/…`) are **not currently supported** for new users; anyone can deploy under their **address-based** namespace with no registration. So use:

- `gno.land/p/<OWNER_ADDR>/errata/v0`
- `gno.land/r/<OWNER_ADDR>/erratabank/v0`
- `gno.land/r/<OWNER_ADDR>/erratademo/v0`

where `<OWNER_ADDR>` is the `g1…` address of the user's deploy key. The `/v0` suffix follows the mainnet package layout.

During development, before the user's key exists, use a valid dev address as the namespace: `g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5` (the example address used throughout the official docs; dev-only, never fund or deploy with it). Provide `scripts/set-namespace.sh <g1addr>` that rewrites every `gnomod.toml` `module` line and every import path from the dev address to the user's owner address, then re-runs `gno test ./...`. Document this in the README. Never hardcode the owner of any book to the deployer; book ownership is per caller.

## Repo layout

```
erratabank/
  README.md
  LICENSE                       (MIT unless you find a reason not to; say which)
  .gitignore
  CODEX_PROMPT.md               (this file; keep it)
  gno/
    p/errata/                   -> gno.land/p/<addr>/errata/v0
      gnomod.toml
      errata.gno                (types + markdown rendering, pure, no state)
      errata_test.gno
    r/erratabank/               -> gno.land/r/<addr>/erratabank/v0
      gnomod.toml
      erratabank.gno            (state + crossing functions)
      render.gno                (Render + routes)
      errors.gno
      erratabank_test.gno
      filetests/*_filetest.gno  (payment and permission flows)
    r/erratademo/               -> gno.land/r/<addr>/erratademo/v0
      gnomod.toml
      erratademo.gno            (a tiny "docs page" realm that shows its errata section via p/errata + r/erratabank)
  scripts/
    set-namespace.sh
    deploy-onyx.sh              (user runs it; prompts for password; deploy order p -> r/erratabank -> r/erratademo)
    demo-onyx.sh                (user runs it; the demo transactions, step by step with pauses)
    query-onyx.sh               (read-only qrender/qeval queries you may run yourself)
  docs/
    DEMO_SCRIPT.md              (~3 minute walkthrough for the video)
```

`gnomod.toml` format in v1.8.0 (created by `gno mod init <path>`):

```toml
module = "gno.land/r/<addr>/erratabank/v0"
gno = "0.9"
```

Do not add `replace` (addpkg refuses modules with `replace`). Do not set `private` or `draft`.

## Gno language facts you must follow

- Crossing functions take `cur realm` as the first parameter (`func Submit(cur realm, ...)`). Callers cross with `fn(cross(cur), ...)`; from `gnokey maketx call` it happens automatically. Non-mutating exported readers take no realm.
- Caller identity: inside a crossing function, `if !cur.IsCurrent() { panic(...) }` then `caller := cur.Previous().Address()`. Never use `unsafe.OriginCaller()` or `unsafe.PreviousRealm()` for authorization (security guide 5.6 and 5.8).
- Payments: any function that reads `unsafe.OriginSend()` must first require `cur.Previous().IsUserCall()` (not `IsUser()`), per security guide 5.5 and Effective Gno "Verifying inbound Coin payments". Only accept denom `ugnot`; reject other denoms and zero/negative amounts.
- Banker: `import "chain/banker"`; `b := banker.NewBanker(banker.BankerTypeRealmSend, cur)`; realm address is `cur.Address()`; send with `b.SendCoins(cur.Address(), to, chain.NewCoins(chain.NewCoin("ugnot", amt)))`. Read balance with `banker.NewReadonlyBanker().GetCoin(addr, "ugnot")`. Imports: `"chain"`, `"chain/banker"`, `"chain/runtime"` (for `runtime.ChainHeight()`), `"chain/runtime/unsafe"` (only for `OriginSend`). Copy the shape from `r/demo/disperse`.
- Events: `chain.Emit("ErratumAccepted", "book", id, "erratum", eid, "finder", addr.String(), "paid", amtStr)` for each state change.
- State: use `gno.land/p/nt/avl/v0` trees (`avl.NewTree()`, `Set`, `Get` returns `any`, `Has`, `Iterate`, `ReverseIterateByOffset`) and `gno.land/p/nt/seqid/v0` (or zero-padded keys) for ids. Use `gno.land/p/nt/ufmt/v0` for formatting.
- Never export pointers to mutable state or return internal `*avl.Tree`/struct pointers from exported functions (security guide 5.1). Exported readers return value copies (structs or slices of structs).
- Never store a `realm` value. Never accept caller-supplied callbacks.
- Render: `func Render(path string) string` returns Markdown. Route with `gno.land/p/nt/mux/v0`. Escape all user-supplied text with `gno.land/p/nt/markdown/sanitize/v0` (pick the helper that matches the slot: inline text, link text, URL, table cell). Never iterate a Go map to build Render output (non-deterministic order); use avl trees. Paginate long lists (e.g. `?page=2`, 20 per page).
- Use `runtime.ChainHeight()` as the canonical "found at" ordering. You may also show block time with `time.Now()` if it compiles in v1.8.0.
- Limit sizes: title ≤ 120 chars, location ≤ 120, text ≤ 1000, link ≤ 300; reject empty fields.

## Realm `gno.land/r/<addr>/erratabank/v0` (spec)

Types (realm-declared):

- `Book{ID, Owner address, Title, Edition, Link, RewardPerErratum int64 (ugnot, 0 = credit only), Escrow int64 (ugnot held for this book), Reserved int64 (0 unless you add reservations), Open bool, CreatedAt int64 height}`
- `Erratum{ID, BookID, Finder address, Location, Text, Status (Pending|Accepted|Rejected|Duplicate), DuplicateOf (id or 0), SubmittedAt height, ReviewedAt height, Paid int64, Note string (owner's short reason)}`
- Per-finder stats: accepted count, total paid, list of erratum ids.

Crossing functions (all check `cur.IsCurrent()`):

1. `CreateBook(cur, title, edition, link string, rewardPerErratum int64) int` — caller becomes owner. If coins are sent, they become the book's escrow (requires `IsUserCall()`, ugnot only). `rewardPerErratum` may be 0 (credit only). If >0, escrow may still be 0 at creation (top up later); then accepted errata are credited but unpaid until funded — and record `Paid=0`. Decide and document: unpaid credits are **not** retro-paid automatically (keep it simple and honest).
2. `FundBook(cur, bookID int)` — anyone may add escrow (requires `IsUserCall()`, ugnot only, amount > 0).
3. `Submit(cur, bookID int, location, text string) int` — book must be open; finder must not be the book owner (no self-rewards); returns erratum id. Store `SubmittedAt = runtime.ChainHeight()`.
4. `Accept(cur, erratumID int, note string)` — owner only; status must be Pending. If `RewardPerErratum > 0` and `Escrow >= RewardPerErratum`, pay exactly `RewardPerErratum` to the finder; otherwise accept as credit-only with `Paid=0` (no partial payouts). Update state (status, escrow, finder stats) before sending coins. Emit an event.
5. `Reject(cur, erratumID int, note string)` — owner only; Pending → Rejected.
6. `MarkDuplicate(cur, erratumID, originalID int)` — owner only; both in the same book; the erratum must be Pending; **the original must have been submitted earlier (`original.ID < erratum.ID`)** and must be Pending or Accepted. This enforces first-finder-wins: a later submission can never take credit from an earlier one, and an earlier submission can never be marked a duplicate of a later one.
7. `SetBookOpen(cur, bookID int, open bool)` — owner only.
8. `Withdraw(cur, bookID int, amount int64)` — owner only; amount > 0 and ≤ unreserved escrow; sends ugnot to the owner; reduce escrow first.
9. Optional: `TransferBook(cur, bookID int, newOwner address)` — owner only, two-step (`ProposeOwner` + `AcceptOwner` by the new owner) to avoid typos. Skip if time is short.

Read-only exported functions (no realm param, return copies):

- `GetBook(id int) (Book, bool)`, `ListBooks(offset, limit int) []Book`
- `GetErratum(id int) (Erratum, bool)`, `ListErrata(bookID int, status string, offset, limit int) []Erratum`
- `AcceptedEntries(bookID int) []errata.Entry` — converts accepted errata to the package type for other realms.
- `FinderStats(addr address) (accepted int, paid int64)`

Render routes (gnoweb at `https://onyx.testnets.gno.land/r/<addr>/erratabank/v0:<route>`):

- `` (home): what Erratabank is (3 lines), how to use it (submit, review), list of books with title, owner (short address), reward, escrow, accepted count, link to each book. Footer: "Started 23 Nov 2026 for Gnome Tavern."
- `book/{id}`: book header (title, edition, link, owner, reward, escrow left, open/closed) + **Accepted errata** table (location, text, finder link, height found, paid) + Pending count + Rejected/Duplicate counts (collapsed list or link).
- `book/{id}/pending`, `book/{id}/all`: paginated lists.
- `erratum/{id}`: full detail with status history.
- `finder/{g1addr}`: the finder's "account page": total accepted, total paid (ugnot and GNOT), table of finds with book links. Validate the address segment with the sanitize package's bech32 validator before using it.
- Use relative links of the form `/r/<addr>/erratabank/v0:book/1` (derive the prefix from the realm's own package path at runtime, do not hardcode the dev address).

Amounts: show both `ugnot` and GNOT (1 GNOT = 1,000,000 ugnot).

## Package `gno.land/p/<addr>/errata/v0` (spec)

Pure package, no state, importable by any realm:

- `type Entry struct { Location, Text, Finder string; FoundAt int64; Paid int64; Link string }`
- `func RenderSection(title string, entries []Entry) string` — returns a Markdown "Errata" section (heading, table or list, "No errata yet." when empty). Sanitizes every field.
- `func FormatUgnot(amount int64) string` — e.g. `2.56 GNOT (2560000 ugnot)`.
- `func ShortAddr(addr string) string` — `g1abcd…wxyz`.
- Unit tests for each, including escaping of hostile input (`|`, `*`, `[x](javascript:…)`, newlines, HTML).

`r/erratabank` must itself use `errata.RenderSection` for the accepted-errata table (dogfooding), so the package is real and exercised.

## Demo realm `gno.land/r/<addr>/erratademo/v0`

A tiny "documentation page" realm (e.g. a short guide titled "Erratabank Quickstart") whose `Render("")` shows its own content and then an Errata section built from `erratabank.AcceptedEntries(<bookID>)` and `errata.RenderSection`. The book id is set once by its owner through a crossing `SetBook(cur, id int)` (owner = deployer captured in `init()` via the documented pattern; check `cur`/deployer semantics in the docs and source). This proves the adoption story: other realms can import it.

## Tests (must pass with `gno test ./...` in each dir)

Use `_test.gno` tests and/or filetests (filetests are the reliable way to test coin flows; copy the pattern from `r/demo/disperse/filetests`: `testing.IssueCoins`, `testing.SetOriginSend`, `testing.SetRealm(testing.NewUserRealm(addr))`, `chain.PackageAddress(path)`, banker balance checks, and `// Output:` / `// Error:` directives). Cover at least:

1. Create book with escrow: escrow recorded, realm balance increased by the sent amount.
2. FundBook adds escrow; non-ugnot or zero sends rejected.
3. Payment guard: calling a payable function from a non-user-call context is rejected.
4. Submit: empty/oversized fields rejected; owner self-submit rejected; closed book rejected.
5. **First finder wins:** two submissions for the same error; Accept the first; `MarkDuplicate(second, first)` works; `MarkDuplicate(first, second)` is rejected; the duplicate cannot later be accepted.
6. **Reward escrow:** Accept pays exactly `RewardPerErratum` to the finder and lowers escrow; when escrow < reward, Accept credits with `Paid=0` and no coins move.
7. **Unauthorized accept/reject/duplicate/withdraw rejected** (a non-owner address).
8. Reviewing a non-Pending erratum rejected (no double payment).
9. **Withdraw:** owner withdraws part of the unused escrow; over-withdraw rejected; non-owner rejected; balances match.
10. Render: home, book page, finder page, erratum page, unknown route, hostile text is escaped, pagination works.
11. Package tests for `errata`.

Also run `gno lint ./...` clean. Add a `Makefile` (or `scripts/test.sh`) that runs fmt/lint/test for all three packages.

## Steps the user must do himself (document in README; never do these for him)

1. Install the tools (command above).
2. Create two local keys in his own Terminal, one to own/deploy and one to act as a reader in the demo:
   ```bash
   gnokey add erratabank-owner
   gnokey add erratabank-reader
   ```
   gnokey prints a 24-word mnemonic for each. He writes them down offline. He never pastes them anywhere (not into Codex, not into chat, not into files).
3. `gnokey list` shows each `g1…` address. He gives Codex only the **owner address** (public).
4. Fund both addresses on https://faucet.gno.land (choose the current testnet).
5. Check funds (read-only, you may run this):
   ```bash
   gnokey query bank/balances/<g1addr> -remote https://rpc.onyx.testnets.gno.land:443
   ```

## Deploy (only after step 5 confirms funds)

1. `scripts/set-namespace.sh <owner g1addr>` then `gno test ./...` again.
2. `scripts/deploy-onyx.sh` — the user runs it. It deploys, in order, `p/…/errata/v0`, `r/…/erratabank/v0`, `r/…/erratademo/v0`, each with:
   ```bash
   gnokey maketx addpkg \
     -pkgpath "gno.land/r/<owner g1addr>/erratabank/v0" \
     -pkgdir ./gno/r/erratabank \
     -gas-fee <fee>ugnot -gas-wanted <gas> \
     -max-deposit <cap>ugnot \
     -chainid onyx-1 -remote https://rpc.onyx.testnets.gno.land:443 \
     erratabank-owner
   ```
   Size gas first with `-simulate only` (the script can run that step and print the suggested gas, then do the real deploy). Wait a few seconds between packages; if a later deploy fails because an import is not yet enabled, wait and retry, and check `https://gpas.latest.testnets.gno.land`.
3. Verify: open `https://onyx.testnets.gno.land/r/<owner g1addr>/erratabank/v0` and the demo realm; run `scripts/query-onyx.sh` (`gnokey query vm/qrender -data "gno.land/r/<addr>/erratabank/v0:" -remote https://rpc.onyx.testnets.gno.land:443`).
4. `scripts/demo-onyx.sh` (user runs it): CreateBook with a small reward (e.g. reward 1000000ugnot and `-send 3000000ugnot`) → reader submits two errata and a duplicate → owner accepts one (paid), marks the duplicate, rejects one → owner withdraws part of the remaining escrow → demo realm SetBook. Print the gnoweb links after each step.

Calls use the same shape, e.g.:

```bash
gnokey maketx call \
  -pkgpath "gno.land/r/<addr>/erratabank/v0" -func "Submit" \
  -args "1" -args "p. 42, line 3" -args "Says O(n log n); should be O(n^2)." \
  -gas-fee <fee>ugnot -gas-wanted <gas> \
  -chainid onyx-1 -remote https://rpc.onyx.testnets.gno.land:443 \
  erratabank-reader
```

(Payable calls add `-send <amount>ugnot`.) Verify exact flag names against `gnokey maketx call --help` and `gnokey maketx addpkg --help` on the installed version.

## README requirements

- Name, one-line pitch, the problem (scattered errata pages, disputes over who found an error first, no portable credit for readers) and who it is for (authors, course makers, doc maintainers anywhere).
- Honest note: "Erratabank was started on 23 Nov 2026 for the Gnome Tavern hackathon. Nothing existed before that date."
- Deployment links section with placeholders until deployed: `Realm: https://onyx.testnets.gno.land/r/<addr>/erratabank/v0`, `Package: …/p/<addr>/errata/v0`, `Demo realm: …/r/<addr>/erratademo/v0`, chain id `onyx-1`.
- How it works (first-finder rule, escrow and payout rules, credit-only mode, withdraw).
- How to use as an author (gnoweb Actions tab with Adena, or gnokey commands), as a reader, and as a realm developer importing `p/…/errata/v0` (code snippet).
- Local dev: install, `gnodev`, tests, lint.
- Key setup and faucet steps (exactly as above, with the "never share your mnemonic" warning).
- Deploy steps and scripts.
- Security notes: which guide rules you followed (IsCurrent, IsUserCall for payments, no exported pointers, sanitized Render).
- Demo script summary (link `docs/DEMO_SCRIPT.md`).
- What was tested, honestly: which tests pass, whether gnodev was run, whether the Onyx deploy happened (and links) or not yet.
- Author: Toyyib Olamilekan. No location.

## docs/DEMO_SCRIPT.md

A ~3 minute walkthrough for a screen recording, no self-intro, in this order: problem in one sentence → book page on gnoweb → reader submits an erratum via the Actions tab or gnokey → owner accepts → finder page shows credit and payment, balances change → duplicate is marked and cannot take credit → demo realm shows the same errata section through the package → withdraw unused escrow → close with "Thanks for watching." Keep each step to a short sentence the narrator can read.

## Done when

- `gno test ./...` and `gno lint ./...` pass for `p/errata`, `r/erratabank`, `r/erratademo`, covering every test listed above.
- `gnodev` loads all three packages and the Render pages look right at http://localhost:8888 (say so in the README; include short notes of what you saw).
- Scripts exist and are correct, but signing scripts are left for the user to run.
- No secrets in git. No remote added. Nothing pushed. Nothing on mainnet.
- README and DEMO_SCRIPT complete and honest.
- Final message to the user lists: files created, test results, exact commands he must run next (key creation, faucet, set-namespace, deploy, demo), and anything you could not verify.
