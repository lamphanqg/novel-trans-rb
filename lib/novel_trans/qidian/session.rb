require "fileutils"
require "playwright"

module NovelTrans
  module Qidian
    class Session
      def self.login(stdin: $stdin, stdout: $stdout)
        FileUtils.mkdir_p(File.dirname(NovelTrans.auth_path))
        Playwright.create(playwright_cli_executable_path: NovelTrans.playwright_cli) do |playwright|
          with_browser(playwright) do |browser|
            browser.new_context do |context|
              page = context.new_page
              page.goto("https://www.qidian.com/", waitUntil: "domcontentloaded")
              stdout.puts <<~MSG
                Log in on https://www.qidian.com/ (QR is more reliable than password plus captcha).
                If Tencent says 操作过于频繁, stop sliding. Wait a while and try again; retries make the block worse.
                After you see your avatar, press Enter here to save auth/qidian.storageState.json
              MSG
              stdin.gets
              context.storage_state(path: NovelTrans.auth_path)
            end
          end
        end
        NovelTrans.auth_path
      end

      def self.with_cdp_browser(endpoint, &block)
        Playwright.create(playwright_cli_executable_path: NovelTrans.playwright_cli) do |playwright|
          playwright.chromium.connect_over_cdp(endpoint) do |browser|
            if browser.contexts.empty?
              raise Error, "no Chrome window at #{endpoint}. Run bin/qidian-chrome, log in on qidian.com, then retry."
            end

            block.call(browser)
          end
        end
      end

      def self.chapter_id_from_url(url)
        Catalog.parse_chapter_url(url)[:chapter_id]
      rescue ArgumentError
        nil
      end

      def self.find_chapter_page(browser, chapter_id)
        want = chapter_id.to_s
        browser.contexts.each do |context|
          context.pages.each do |page|
            return page if chapter_id_from_url(page.url) == want
          end
        end
        nil
      end

      def self.blank_or_new_page(browser)
        context = browser.contexts.first
        blank = context.pages.find do |page|
          u = page.url.to_s
          u.empty? || u.start_with?("about:") || u.start_with?("chrome://")
        end
        blank || context.new_page
      end

      def self.with_browser(playwright, &)
        playwright.chromium.launch(headless: false, channel: "chrome", &)
      rescue Playwright::Error
        playwright.chromium.launch(headless: false, &)
      end
    end
  end
end
