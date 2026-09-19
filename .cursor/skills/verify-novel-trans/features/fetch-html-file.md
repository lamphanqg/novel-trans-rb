# Offline chapter fetch

Replay a saved Qidian chapter DOM from disk into `input/raw/<book>/<chapter>.txt` and update the JSON ledger without Chrome or the network.

## Sub-features

- `fetch-unlocked` parses VIP-unlocked HTML and sets status `fetched`.
- `fetch-skip` skips an already `fetched` chapter unless `--force`.
- `fetch-locked` sets `locked` and does not keep raw text (use `chapter_locked.html`).
- `fetch-pua` sets `failed` for PUA font-lock HTML.

## How to get to it (user POV)

- Run `bin/novel-trans fetch --book <book_id> --html-file <path> --chapter-id <chapter_id>`.
- Use paths under `spec/fixtures/qidian/` for deterministic verification.

## Driving it with verify-novel-trans

Preconditions:

- `verify-novel-trans doctor` passes.
- `verify-novel-trans cleanup-data` if you need a clean slate for book `1036645930`.
- Fixture file `spec/fixtures/qidian/chapter_unlocked.html` exists.

- **Baseline status.** Run `verify-novel-trans cli -- status --book 1036645930`. Note `total` (often `0` after cleanup).
- **Fetch unlocked.** Run `verify-novel-trans cli -- fetch --book 1036645930 --html-file spec/fixtures/qidian/chapter_unlocked.html --chapter-id 747314648`. Exit `0`; stdout contains `fetched 747314648`.
- **Confirm ledger.** Run `verify-novel-trans cli -- status --book 1036645930 --status fetched`. stdout lists chapter `747314648`.
- **Confirm raw file.** Run `head -n 3 input/raw/1036645930/747314648.txt` and append output to `evidence/<RUN_ID>/raw-head.txt`. Content includes `第一章 开场`.
- **Idempotent skip.** Run the same `fetch` command again. stdout contains `skip 747314648`.
- **Proof.** Keep transcripts `cli-fetch_…`, `cli-status_…`, and `raw-head.txt` under `evidence/<RUN_ID>/`.

## Gotchas

- `--chapter-id` is required with `--html-file`; omitting it raises before parsing.
- Book id in the CLI must match fixture URLs embedded in HTML when applicable.
- Second fetch without `--force` does not rewrite raw text; use `--force` to prove rewrite behavior.
- Do not confuse this path with live `--url` fetch, which always needs CDP.
