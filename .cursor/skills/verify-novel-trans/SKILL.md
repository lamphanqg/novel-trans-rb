---
name: verify-novel-trans
description: "Verify novel-trans via bin/test for logic and optional live E2E (bin/qidian-chrome CDP) with operator help. Default CLI drive uses fixtures; live fetch/translate capped at one chapter. Evidence is gitignored."
---

# Verify novel-trans (Thor CLI)

Primary surface is `bin/novel-trans` in the repo root. There is no web UI.

## Verification policy

| Layer | When | How |
|-------|------|-----|
| **Unit** | Default proof for logic, parsers, ledger, CLI wiring | `bin/test` (full suite) and/or targeted `bundle exec rspec path/to/spec` |
| **E2E (CLI)** | Operator session; real CDP Chrome | `bin/qidian-chrome` (port **9222**), operator keeps Chrome up and handles login/captcha |
| **E2E (offline)** | No network; cheap smoke of fetch/status | `fetch --html-file` + fixture under `spec/fixtures/qidian/` |

Live Qidian is **allowed** when an operator is present. Do not treat it as forbidden. Do not kill or restart the operator's Chrome — attach only via the `qidian-chrome` profile.

**Cost cap (live fetch / translate):**

- Never run a full catalog walk or full-book `translate` as verification.
- Default live drive: **one chapter** — prefer `fetch --book <id> --url '<single chapter url>'` over bare `fetch --book`.
- If you must exercise catalog mode locally, set `NOVEL_TRANS_CHAPTER_LIMIT=1` (operator env; caps how many catalog chapters are processed when supported).
- Live `translate`: at most one `fetched` chapter for the book under test (fixture fetch one chapter first, or translate a single known row).

**Evidence:** per-run logs under gitignored `.cursor/skills/verify-novel-trans/evidence/` — never commit.

## Launch

One-time (or after Gemfile changes):

```sh
cd /path/to/novel-trans-rb
bin/setup
```

**Ready signal:** `bin/novel-trans help` exits `0`. Empty argv prints help and exits `1` (by design).

**Unit gate (run before or after CLI drives):**

```sh
bin/test
# e.g. bundle exec rspec spec/qidian/book_fetch_spec.rb spec/cli_spec.rb
```

**CLI doctor (fixture drives):**

```sh
.cursor/skills/verify-novel-trans/bin/verify-novel-trans doctor
```

**E2E:** operator starts `bin/qidian-chrome` in another terminal; agent uses `fetch` with a single `--url` (see [features/fetch-live-catalog.md](./features/fetch-live-catalog.md)).

**Teardown:** No daemon to stop except leaving operator Chrome running. Run `cleanup-data` for fixture book `1036645930` when done with offline/smoke data.

## Doctor

Read-only gate before **fixture** CLI drives (no Chrome required):

```sh
RUN_ID=my-run .cursor/skills/verify-novel-trans/bin/verify-novel-trans doctor
```

Expect `doctor: all checks passed`. For live E2E, additionally confirm CDP responds (e.g. port 9222) and the operator confirms Qidian login — do not read or commit `auth/`.

## Drive

### Unit (default for logic changes)

```sh
bin/test
```

Use focused specs when the change is narrow; green specs are the default proof that ledger, parse, and CLI behavior hold.

### Offline CLI smoke (no Qidian)

Harness: `verify-novel-trans cli --` for gitignored transcripts.

**Isolation:** fixture book `1036645930`, chapter `747314648`. Data under gitignored `var/ledger/`, `input/raw/`, `output/vi/`.

```sh
export RUN_ID=my-run-id
HELPER=.cursor/skills/verify-novel-trans/bin/verify-novel-trans

$HELPER cli -- fetch --book 1036645930 \
  --html-file spec/fixtures/qidian/chapter_unlocked.html \
  --chapter-id 747314648
$HELPER cli -- status --book 1036645930 --status fetched
```

Assert `fetched 747314648` and raw text includes `第一章 开场`. See [features/fetch-html-file.md](./features/fetch-html-file.md).

### Live E2E (operator + CDP)

1. Operator runs `bin/qidian-chrome` and stays logged in.
2. Agent runs **one** URL fetch, records transcript via `$HELPER cli --`:

```sh
export RUN_ID=my-run-id
HELPER=.cursor/skills/verify-novel-trans/bin/verify-novel-trans

$HELPER cli -- fetch --book <book_id> \
  --url 'https://www.qidian.com/chapter/<book_id>/<chapter_id>/'
$HELPER cli -- status --book <book_id> --status fetched
```

Do not run `fetch --book <id>` without `--url` for verification (catalog walk). See feature map: [features/README.md](./features/README.md).

## Evidence

Per-run logs only — **never commit**. `.cursor/skills/verify-novel-trans/evidence/<RUN_ID>/` is gitignored.

- **Unit:** RSpec output can be tee'd to `evidence/<RUN_ID>/rspec.txt` locally; same gitignore rules.
- **CLI:** helper writes `cli-*.txt` (command, cwd, timestamp, stdout/stderr, exit code).

Copy `evidence/<RUN_ID>/` to Project media when proof must be shared outside the checkout.

## Cleanup

```sh
.cursor/skills/verify-novel-trans/bin/verify-novel-trans cleanup-data
```

Removes fixture-book paths under `var/ledger/`, `input/raw/`, `output/vi/` for `1036645930` only. Does not delete `evidence/` or operator `auth/`. Never `pkill` Chrome.

## Helpers

```sh
.cursor/skills/verify-novel-trans/bin/verify-novel-trans doctor
.cursor/skills/verify-novel-trans/bin/verify-novel-trans cli -- help fetch
.cursor/skills/verify-novel-trans/bin/verify-novel-trans cleanup-data
.cursor/skills/verify-novel-trans/bin/verify-novel-trans evidence-dir
```

## Maintenance

When commands, flags, or fixture ids change, update this skill and the feature map, then run `/maintain-verification-skill`.
