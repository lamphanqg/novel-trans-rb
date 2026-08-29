# novel-trans-rb

Personal pipeline. Scrape Qidian chapters you already paid for, translate them to Vietnamese, keep `.txt` on a private R2 prefix, and publish a static reader under `www/`. Do not share the reader URL. This is for personal use.

## Setup

```sh
bin/setup
```

Installs gems into `vendor/bundle`, installs matching `playwright-core` via npm, and downloads Chromium. Needs Ruby, Bundler, and Node.js.

## Check the tree

```sh
bin/test
bin/lint
bin/novel-trans help
bin/novel-trans status --book 1036645930
bin/novel-trans status --book 1036645930 --status failed
```

`status` prints counts by status. Pass `--status` to print matching chapter rows.

Live fetch attaches to Google Chrome started with `bin/qidian-chrome` (profile under `auth/chrome-profile`). Log in there once (QR). Playwright-launched Chrome does not get VIP chapter HTML.

```sh
bin/qidian-chrome   # leave this running

bin/novel-trans fetch --book 1016572786 \
  --url 'https://www.qidian.com/chapter/1016572786/514924883/'
```

`--url` is repeatable. Each URL must belong to `--book`. `--html-file` plus `--chapter-id` replays a saved rendered DOM without a browser. `--force` rewrites a chapter that is already `fetched`. Catalog (whole-book) fetch, `login`, `translate`, `upload`, `run`, and `site` are not implemented yet. Thor reserves the method name `run`, so the command is registered as `pipeline` and `bin/novel-trans run` is an alias.

## Config later

`config/novels.yml` will list books. `config/vocab/{book_id}.yml` will hold per-novel names.

Translations stay in a private bucket except the HTML reader prefix described in the plan.
