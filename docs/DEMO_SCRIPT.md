# Erratabank v1 demo

Use this walkthrough with `scripts/demo-onyx.sh` on a fresh, unlinked v1 deployment. The script uses four funded testnet accounts for the owner, sponsor, first reader, and second reader. Capture the result of each call after the Terminal prompt closes.

| Time | Show | Say |
| --- | --- | --- |
| 0:00–0:20 | Create the Quickstart book and open its gnoweb page. | “The owner sets a reward of one GNOT per eligible correction and deposits a quarter GNOT of owner funds.” |
| 0:20–0:35 | Fund the book with the sponsor account. | “The sponsor adds one GNOT, which the book labels as locked sponsor funds.” |
| 0:35–0:55 | Submit the two Section 1 corrections from separate reader accounts. | “The first reader reports the missing backtick. A second reader reports the same location afterward.” |
| 0:55–1:20 | Accept the first report and open that reader's finder page. | “The owner accepts the first report. The finder receives one GNOT from the sponsor balance.” |
| 1:20–1:35 | Mark the later report as a duplicate and follow its link. | “The later report points to the first finder’s accepted correction.” |
| 1:35–2:00 | Use the second reader to submit the Section 2 correction. Accept it and open the finder page. | “The second reader finds a separate issue in Section 2. The owner accepts it. The book is short on funds, so one GNOT is recorded as owed.” |
| 2:00–2:20 | Top up 1.1 GNOT with the sponsor account and refresh the finder and book pages. | “The sponsor tops up one point one GNOT. The owed reward is paid first, leaving a tenth of a GNOT in locked sponsor funds.” |
| 2:20–2:40 | Withdraw the owner’s 0.25 GNOT and show both book balances. | “The owner takes back their quarter GNOT of unreserved deposits. The tenth GNOT from the sponsor stays locked.” |
| 2:40–3:00 | Link the guide and show both accepted corrections under Errata. | “The Quickstart guide shows both accepted corrections through the paged integration API. Thanks for watching.” |

The [recorded Onyx v0 demo](../README.md#verified-onyx-demo-24-nov-2026) documents the earlier four-transaction run.
