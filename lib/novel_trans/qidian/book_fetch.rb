module NovelTrans
  module Qidian
    class BookFetch
      def initialize(book_id:, force: false, html_file: nil, chapter_id: nil, urls: [])
        @book_id = book_id.to_s
        @force = force
        @html_file = html_file
        @chapter_id = chapter_id
        @urls = Array(urls).compact.reject(&:empty?)
        @persist = ChapterPersist.new(book_id: @book_id, force:)
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
        if @persist.skip?(chapter_id)
          puts "skip #{chapter_id}"
          return
        end

        @persist.apply_result(ChapterPage.parse(html, chapter_id:), chapter_id)
      end

      private

      def required_chapter_id
        raise ArgumentError, "--chapter-id is required with --html-file" if @chapter_id.to_s.empty?

        @chapter_id.to_s
      end

      def fetch_urls
        pending = []
        @urls.each do |url|
          chapter_id = chapter_id_for_url(url)
          if @persist.skip?(chapter_id)
            puts "skip #{chapter_id}"
          else
            pending << [url, chapter_id]
          end
        end
        return if pending.empty?

        Session.connect do |session|
          pending.each_with_index do |(url, chapter_id), i|
            session.pause if i != 0
            fetch_one_url(session, url, chapter_id)
          end
        end
      end

      def fetch_catalog
        Session.connect do |session|
          page = session.blank_or_new_page
          pending_catalog_items(page, session).each do |item|
            session.pause
            page.goto(item.url, waitUntil: "domcontentloaded", timeout: 30_000)
            session.wait_for_chapter(page, item.chapter_id)
            @persist.apply_result(ChapterPage.from_page(page, chapter_id: item.chapter_id), item.chapter_id)
          end
        end
      end

      def pending_catalog_items(page, session)
        items = Catalog.parse(Catalog.html_from_page(page, @book_id, session:))
        pending = []
        items.each do |item|
          next unless item.book_id == @book_id

          if @persist.skip?(item.chapter_id)
            puts "skip #{item.chapter_id}"
          else
            pending << item
          end
        end
        pending
      end

      def fetch_one_url(session, url, chapter_id)
        page = session.find_chapter_page(chapter_id)
        if page
          puts "using open tab #{page.url}"
        else
          page = session.blank_or_new_page
          puts "no open tab for #{chapter_id}, navigating"
          page.goto(url, waitUntil: "domcontentloaded", timeout: 30_000)
        end
        session.wait_for_chapter(page, chapter_id)
        @persist.apply_result(ChapterPage.from_page(page, chapter_id:), chapter_id)
      end

      def chapter_id_for_url(url)
        ids = Catalog.parse_chapter_url(url)
        unless ids[:book_id] == @book_id
          raise ArgumentError, "URL book #{ids[:book_id]} does not match --book #{@book_id}"
        end

        ids[:chapter_id]
      end
    end
  end
end
