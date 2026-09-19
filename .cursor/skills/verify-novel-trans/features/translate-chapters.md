# Translate fetched chapters

`translate` runs `cursor agent` on `fetched` chapters and writes Vietnamese text to `output/vi/<book>/<chapter>.txt`, advancing ledger status to `translated`.

## Sub-features

- `translate-batch` processes all `fetched` chapters for `--book` (normal use; not for verify at scale).
- `translate-skip` skips `translated` / `uploaded` unless `--force`.
- `translate-model` respects `CURSOR_MODEL` override documented in help.

## How to get to it (user POV)

- After chapters are `fetched`, run `bin/novel-trans translate --book <book_id>`.
- Pass `--force` to re-translate completed chapters.

## Driving it with verify-novel-trans

Preconditions:

- **Unit (default):** `bin/test` / `spec/book_translate_spec.rb` (and related specs) prove translate wiring without calling Cursor.
- **Live E2E:** exactly **one** `fetched` chapter for the book (from fixture fetch or one live `--url` fetch). Operator accepts Cursor API cost.
- `cursor agent` on PATH and authenticated.

- **Surface proof.** `verify-novel-trans cli -- help translate` — stdout references `cursor agent`.
- **Live E2E (one chapter).** Ensure only one row is `fetched` (fixture book `1036645930` + single chapter, or operator book with one pending chapter). Run `verify-novel-trans cli -- translate --book <book_id>`. Then `status --book <book_id> --status translated` and inspect **one** file under `output/vi/<book_id>/`.
- **Forbidden for verify:** `translate --book` when many chapters are `fetched` (full-book translate).

## Gotchas

- Translation spends model quota; cap at one chapter per verify run.
- `cursor agent` uses `--workspace` set to the repo root.
- Failed agent runs set chapter status `failed`; use `cleanup-data` for fixture book `1036645930` when experimenting.
- Logic changes should be proven with `bin/test` first; live translate is optional E2E with operator approval.
