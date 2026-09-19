# Ledger status

`status` reports per-book chapter workflow counts (`pending`, `locked`, `fetched`, `translated`, `uploaded`, `failed`) or lists rows matching one status.

## Sub-features

- `status-counts` prints a TSV tally for every status plus `total`.
- `status-filter` prints `book_id`, `chapter_id`, `status` rows for `--status`.
- `status-unknown` rejects invalid `--status` values.

## How to get to it (user POV)

- Run `bin/novel-trans status --book <book_id>`.
- Add `--status fetched` (or another valid status) to list matching chapters.

## Driving it with verify-novel-trans

Preconditions:

- `verify-novel-trans doctor` passes.
- For non-empty counts, run [offline chapter fetch](./fetch-html-file.md) first or use existing gitignored ledger data for book `1036645930`.

- **Empty baseline.** Run `verify-novel-trans cli -- status --book 1036645930`. Exit `0`; stdout shows `total	0` (or current count).
- **After fixture fetch.** Run `verify-novel-trans cli -- status --book 1036645930 --status fetched`. Exit `0`; stdout includes a row `1036645930	747314648	fetched`.
- **Invalid filter.** Run `bin/novel-trans status --book 1036645930 --status done` (no helper required). Expect non-zero exit and `unknown status` on stderr.
- **Proof.** Transcript shows the TSV header and the fetched row after a fixture fetch drive.

## Gotchas

- Ledger files live under `var/ledger/` (gitignored). A clean clone shows zeros until something mutates the book.
- `status` creates `var/ledger` directories if missing; that is a side effect but not chapter data.
- Counts include all chapters for the book, not only the verify fixture chapter.
