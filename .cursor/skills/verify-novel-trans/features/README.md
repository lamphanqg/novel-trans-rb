# novel-trans CLI verification map

Maintained source for verifying user-facing behavior of `bin/novel-trans`. Read this index before driving the CLI, then open the feature file for the recipe.

## Verification layers

- **Unit (default):** `bin/test` and/or targeted `bundle exec rspec` — primary proof for logic.
- **E2E offline:** fixture `fetch --html-file`, `status`, `help` — no Qidian.
- **E2E live:** operator runs `bin/qidian-chrome` (CDP 9222); agent may fetch **one** `--url` or translate **one** `fetched` chapter. Operator handles login/captcha.
- **Cost cap:** no full catalog `fetch` or full-book `translate` in verify; use `NOVEL_TRANS_CHAPTER_LIMIT=1` only if catalog mode is unavoidable locally.

## Baseline preconditions

- Repo root with `bin/setup` completed (`vendor/bundle` present).
- Working directory is the repository root.
- Fixture book `1036645930` / chapter `747314648` for offline smoke unless a live feature names another book.
- `verify-novel-trans doctor` before offline CLI drives.
- Set `RUN_ID` for gitignored transcripts under `evidence/<RUN_ID>/`.

## Driving conventions

- Run `bin/test` when changing Ruby behavior; CLI drives supplement, not replace, specs.
- Prefer `verify-novel-trans cli -- …` for captured stdout/stderr (gitignored).
- Treat Thor flags literally (`--book`, `--html-file`, `--chapter-id`, `--url`, `--status`, `--force`).
- Live Qidian is allowed with operator + CDP; default cloud agents use fixtures + unit tests.
- After mutating fixture data, run `verify-novel-trans cleanup-data`; keep evidence local only.

## Proof and skip reporting

- CLI proof includes command, stdout, stderr, and exit code in gitignored `evidence/<RUN_ID>/cli-*.txt`.
- Copy `evidence/<RUN_ID>/` to Project media when proof must be shared; do not add run logs to the repo.
- Mutation proof includes a read-only follow-up (`status` or `head` of `input/raw/...`).
- Record feature id and entry point on every artifact.
- Report unreachable paths with the attempted command and unmet precondition.
- Do not mark live catalog fetch as verified when only fixture fetch was exercised.

## Feature entry contract

Each feature file has an H1, one summary paragraph, then exactly four H2 sections: `Sub-features`, `How to get to it (user POV)`, `Driving it with verify-novel-trans`, `Gotchas`.

## Features

- [CLI help and discovery](./cli-help.md) — list commands and read per-command help.
- [Ledger status](./status-ledger.md) — counts and filtered chapter rows.
- [Offline chapter fetch](./fetch-html-file.md) — replay saved HTML into raw text and the ledger.
- [Live catalog fetch](./fetch-live-catalog.md) — CDP fetch via `bin/qidian-chrome` (one `--url`; operator session).
- [Translate fetched chapters](./translate-chapters.md) — unit specs + optional one-chapter live `cursor agent`.
