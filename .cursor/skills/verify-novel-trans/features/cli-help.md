# CLI help and discovery

Operators discover available work (`fetch`, `translate`, `status`, stubs) through Thor help without mutating ledger data.

## Sub-features

- `help-top` lists top-level commands from an empty or `help` invocation.
- `help-fetch` documents `--html-file`, `--chapter-id`, `--url`, and `--force`.
- `help-translate` documents Cursor agent integration.
- `help-stubs` shows `login`, `upload`, `pipeline`/`run`, and `site` as commands (may still raise at runtime).

## How to get to it (user POV)

- Run `bin/novel-trans` with no arguments (prints help, exits `1`).
- Run `bin/novel-trans help`.
- Run `bin/novel-trans help <command>` for a subcommand.

## Driving it with verify-novel-trans

Preconditions:

- `verify-novel-trans doctor` passes.
- No Chrome or Qidian session required.

- **Top-level list.** Run `verify-novel-trans cli -- help`. Exit `0`; stdout includes `fetch`, `translate`, and `status`.
- **Fetch flags.** Run `verify-novel-trans cli -- help fetch`. Exit `0`; stdout includes `html-file` and `chapter-id`.
- **Translate surface.** Run `verify-novel-trans cli -- help translate`. Exit `0`; stdout mentions `cursor agent`.
- **Proof.** Save the `cli-help_fetch.txt` (or equivalent) transcript under `evidence/<RUN_ID>/`; it must show the flag names an operator needs for offline fetch.

## Gotchas

- Empty argv is intentional: help prints, exit code is `1`.
- Help text does not prove `login` or `upload` work — those raise `NotImplementedCommand` when invoked.
- Thor registers `pipeline` but `bin/novel-trans run` is an alias; both names may appear in docs.
