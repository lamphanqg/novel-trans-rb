# novel-trans-rb

Personal pipeline to translate Qidian novels you already paid for into Vietnamese and store them on Cloudflare R2. Translations are for personal use. Do not share the reader URL.

## Setup

```sh
bin/setup
bin/lint
```

`bin/setup` needs Ruby, Bundler, and Node.js. Gems go in `vendor/bundle`. Playwright Chromium is installed via `playwright-core`.

The CLI and chapter ledger land in a follow-up change.
