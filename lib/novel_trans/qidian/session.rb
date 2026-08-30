require "playwright"

module NovelTrans
  module Qidian
    class Session
      # Must match --remote-debugging-port in bin/qidian-chrome.
      CDP_ENDPOINT = "http://127.0.0.1:9222".freeze
      PAUSE_RANGE = 2.5..8.0

      def self.connect
        Playwright.create(playwright_cli_executable_path: NovelTrans.playwright_cli) do |playwright|
          browser = attach(playwright)
          begin
            if browser.contexts.empty?
              raise Error, "no Chrome window on 9222. Run bin/qidian-chrome, log in, then retry."
            end

            yield new(browser)
          ensure
            browser.close
          end
        end
      end

      def self.attach(playwright)
        playwright.chromium.connect_over_cdp(CDP_ENDPOINT)
      rescue Playwright::Error
        raise Error, "live fetch needs bin/qidian-chrome. Log in on qidian.com, then retry."
      end
      private_class_method :attach

      def self.chapter_id_from_url(url)
        Catalog.parse_chapter_url(url)[:chapter_id]
      rescue ArgumentError
        nil
      end

      def initialize(browser)
        @browser = browser
      end

      def find_chapter_page(chapter_id)
        want = chapter_id.to_s
        @browser.contexts.each do |context|
          context.pages.each do |page|
            return page if self.class.chapter_id_from_url(page.url) == want
          end
        end
        nil
      end

      def blank_or_new_page
        context = @browser.contexts.first
        blank = context.pages.find do |page|
          u = page.url.to_s
          u.empty? || u.start_with?("about:") || u.start_with?("chrome://")
        end
        blank || context.new_page
      end

      def wait_for_chapter(page, chapter_id)
        page.wait_for_selector("body", timeout: 15_000)
        page.wait_for_selector(
          "#c-#{chapter_id} span.content-text, #c-#{chapter_id} p, #c-#{chapter_id}, main[id^='c-'], h1",
          timeout: 20_000
        )
        # VIP paragraphs often appear a beat after the heading is in the DOM.
        page.wait_for_timeout(2000)
      rescue Playwright::Error
        nil
      end

      def pause
        seconds = rand(PAUSE_RANGE)
        puts "wait #{format('%.1f', seconds)}s"
        sleep(seconds)
      end
    end
  end
end
