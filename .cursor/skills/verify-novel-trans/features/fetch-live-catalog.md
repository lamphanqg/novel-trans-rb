# Live catalog fetch

Download chapters from Qidian while attached to the operator's Google Chrome over CDP (`bin/qidian-chrome`, port 9222). The operator keeps Chrome running and handles login, captcha, and account risk.

## Sub-features

- `fetch-url` fetches one or more explicit `--url` chapters (preferred for verification).
- `fetch-catalog` walks the book catalog with polite delays (not for verify — cost and volume).
- `fetch-chrome-missing` fails fast when CDP is not listening.

## How to get to it (user POV)

- Operator starts `bin/qidian-chrome` and logs into Qidian in that profile (`auth/chrome-profile`, local only).
- Run `bin/novel-trans fetch --book <book_id> --url '<chapter url>'` for targeted chapters.
- Bare `bin/novel-trans fetch --book <book_id>` walks the catalog — normal operation, not verification.

## Driving it with verify-novel-trans

Preconditions:

- Operator machine; `bin/qidian-chrome` listening on CDP (9222).
- Operator available for captcha/login if the session expired.
- **Cost cap:** exactly **one** chapter URL per verify run. No catalog walk.
- Optional: `NOVEL_TRANS_CHAPTER_LIMIT=1` if using catalog mode locally when that env is supported.

- **CDP absent (unit-style).** Without `qidian-chrome`, run `bin/novel-trans fetch --book 1036645930`. Expect error mentioning `qidian-chrome` — proves fail-fast (also covered by `spec/cli_spec.rb`).
- **Live E2E (one chapter).** Operator starts Chrome. Run `verify-novel-trans cli -- fetch --book <book_id> --url 'https://www.qidian.com/chapter/<book_id>/<chapter_id>/'`. Exit `0`; stdout shows `fetched` or `skip` for that id only.
- **Confirm.** `verify-novel-trans cli -- status --book <book_id> --status fetched` lists the chapter row; optionally `head` one line of `input/raw/...` into gitignored evidence.
- **Proof.** Gitignored transcript under `evidence/<RUN_ID>/`; do not commit HTML or auth paths.

Pair with **unit** proof: `bin/test` / `spec/qidian/book_fetch_spec.rb` for parse and ledger logic without Qidian.

## Gotchas

- Never kill the operator's personal Chrome or unrelated profiles; only use `bin/qidian-chrome`.
- Playwright-launched Chromium does not receive VIP HTML — not valid for live proof.
- `fetch --book` without `--url` can download many chapters — forbidden for verify.
- Default agent/cloud runs should use [offline chapter fetch](./fetch-html-file.md) plus `bin/test`; live E2E requires the operator session.
