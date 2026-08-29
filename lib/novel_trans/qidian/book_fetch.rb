require "fileutils"
require "playwright"

module NovelTrans
  module Qidian
    class BookFetch
      def initialize(book_id:, force: false, html_file: nil, chapter_id: nil, urls: [], cdp: nil)
        @book_id = book_id.to_s
        @force = force
        @html_file = html_file
        @chapter_id = chapter_id
        @urls = Array(urls).compact.reject(&:empty?)
        @cdp = cdp
      end

      def run
        if @html_file
          apply_html(File.read(@html_file), chapter_id: required_chapter_id)
          return
        end

        if @urls.any?
          fetch_urls
          return
        end

        fetch_catalog
      end

      def apply_html(html, chapter_id:)
        if skip?(chapter_id)
          puts "skip #{chapter_id}"
          return
        end

        result = ChapterPage.parse(html, chapter_id: chapter_id)
        apply_result(result, chapter_id)
      end

      def apply_page(page, chapter_id)
        if skip?(chapter_id)
          puts "skip #{chapter_id}"
          return
        end

        wait_for_chapter(page, chapter_id)
        apply_result(ChapterPage.from_page(page, chapter_id: chapter_id), chapter_id)
      end

      private

      def required_chapter_id
        raise ArgumentError, "--chapter-id is required with --html-file" if @chapter_id.to_s.empty?

        @chapter_id.to_s
      end

      def require_cdp!
        return unless @cdp.to_s.empty?

        raise Error, "live fetch needs --cdp http://127.0.0.1:9222. Start bin/qidian-chrome first."
      end

      def fetch_urls
        chapter_ids = @urls.map { |url| chapter_id_for_url(url) }
        require_cdp!
        Session.with_cdp_browser(@cdp) do |browser|
          @urls.zip(chapter_ids).each do |url, chapter_id|
            page = Session.find_chapter_page(browser, chapter_id)
            if page
              puts "using open tab #{page.url}"
            else
              page = Session.blank_or_new_page(browser)
              puts "no open tab for #{chapter_id}, navigating"
              page.goto(url, waitUntil: "domcontentloaded", timeout: 30_000)
            end
            apply_page(page, chapter_id)
          end
        end
      end

      def fetch_catalog
        require_cdp!
        Session.with_cdp_browser(@cdp) do |browser|
          page = Session.blank_or_new_page(browser)
          html = Catalog.html_from_page(page, @book_id)
          Catalog.parse(html).each do |item|
            next unless item.book_id == @book_id

            page.goto(item.url, waitUntil: "domcontentloaded", timeout: 30_000)
            apply_page(page, item.chapter_id)
          end
        end
      end

      def chapter_id_for_url(url)
        ids = Catalog.parse_chapter_url(url)
        unless ids[:book_id] == @book_id
          raise ArgumentError, "URL book #{ids[:book_id]} does not match --book #{@book_id}"
        end

        ids[:chapter_id]
      end

      def skip?(chapter_id)
        return false if @force

        path = NovelTrans.raw_path(@book_id, chapter_id)
        return false unless File.file?(path)
        return false unless File.file?(ChapterWork.ledger_path(@book_id, chapter_id))

        ChapterWork.load(@book_id, chapter_id).status == "fetched"
      end

      def wait_for_chapter(page, chapter_id)
        page.wait_for_selector("body", timeout: 15_000)
        page.wait_for_selector(
          "#c-#{chapter_id} span.content-text, #c-#{chapter_id} p, #c-#{chapter_id}, main[id^='c-'], h1",
          timeout: 20_000
        )
        page.wait_for_timeout(2000)
      rescue Playwright::Error
        nil
      end

      def apply_result(result, chapter_id)
        case result.outcome
        when :locked
          write_ledger(chapter_id, "locked")
          FileUtils.rm_f(NovelTrans.raw_path(@book_id, chapter_id))
          puts "locked #{chapter_id}"
        when :pua
          write_ledger(chapter_id, "failed")
          FileUtils.rm_f(NovelTrans.raw_path(@book_id, chapter_id))
          puts "pua_font #{chapter_id}"
        when :ok
          path = NovelTrans.raw_path(@book_id, chapter_id)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, "#{result.title}\n\n#{result.body}\n")
          write_ledger(chapter_id, "fetched")
          puts "fetched #{chapter_id}"
        when :blocked
          write_ledger(chapter_id, "failed")
          FileUtils.rm_f(NovelTrans.raw_path(@book_id, chapter_id))
          puts "failed #{chapter_id} (Qidian refused to render the chapter in this browser)"
          puts "Start bin/qidian-chrome, log in there, then fetch with --cdp http://127.0.0.1:9222 --force"
        else
          write_ledger(chapter_id, "failed")
          FileUtils.rm_f(NovelTrans.raw_path(@book_id, chapter_id))
          puts "failed #{chapter_id} (no chapter body in the DOM)"
        end
      end

      def write_ledger(chapter_id, status)
        ChapterWork.new(book_id: @book_id, chapter_id: chapter_id, status: status).save
      end
    end
  end
end
