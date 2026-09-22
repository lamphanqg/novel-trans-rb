require "playwright"

module NovelTrans
  module Qidian
    class Catalog
      Item = Struct.new(:book_id, :chapter_id, :url, :title, :vip, keyword_init: true)
      CHAPTER_PATH = %r{/chapter/(\d+)/(\d+)/?}
      HREF = %r{href=["'](?:https?:)?(?://[^/"']+)?(/chapter/(\d+)/(\d+)/?)["']}i
      CATALOG_URLS = [
        "https://book.qidian.com/info/%s/#Catalog",
        "https://www.qidian.com/book/%s/",
        "https://book.qidian.com/info/%s/",
        "https://m.qidian.com/book/%s/catalog"
      ].freeze
      CATALOG_READY = "#allCatalog, #j-catalogWrap, #j-catalogList, .catalog-content-wrap".freeze
      CATALOG_LIVE_SCOPE = /id=["']allCatalog["']|class=["'][^"']*catalog-all["']/i
      CATALOG_LEGACY_SCOPE = /id=["']j-catalogWrap["']|id=["']j-catalogList["']|class=["'][^"']*catalog-content-wrap/i
      LIVE_PROMO_STRIP = [
        %r{<div\b[^>]*\bcatalog-newest-con\b[^>]*>.*?</div>}im,
        %r{<a\b[^>]*\bbook-latest-chapter\b[^>]*>.*?</a>}im
      ].freeze

      def self.parse(html)
        items = []
        seen = {}
        catalog_scope(html).split(/<li\b/i).drop(1).each do |chunk|
          item = item_from_li("<li#{chunk}")
          next unless item
          next if seen[item.chapter_id]

          seen[item.chapter_id] = true
          items << item
        end
        items
      end

      def self.item_from_li(fragment)
        match = HREF.match(fragment)
        return unless match

        title_html = fragment[%r{<a\b[^>]*class=["'][^"']*chapter-name[^"']*["'][^>]*>(.*?)</a>}im, 1]
        Item.new(
          book_id: match[2],
          chapter_id: match[3],
          url: "https://www.qidian.com#{match[1]}",
          title: strip_tags(title_html || ""),
          vip: fragment.include?("chapter-locked")
        )
      end

      def self.html_from_page(page, book_id, session:)
        CATALOG_URLS.each_with_index do |template, i|
          session.pause if i != 0
          page.goto(format(template, book_id), waitUntil: "domcontentloaded", timeout: 30_000)
          page.wait_for_selector("body", timeout: 15_000)
          page.wait_for_selector(CATALOG_READY, timeout: 15_000)
          html = page.content
          return html if parse(html).any?
        rescue Playwright::Error
          next
        end
        raise Error, "no catalog chapters for book #{book_id}"
      end

      def self.parse_chapter_url(url)
        match = CHAPTER_PATH.match(url.to_s)
        raise ArgumentError, "not a Qidian chapter URL: #{url}" unless match

        { book_id: match[1], chapter_id: match[2] }
      end

      def self.strip_tags(text)
        text.to_s.gsub(/<[^>]+>/, "").gsub("&nbsp;", " ").strip
      end

      def self.catalog_scope(html)
        html = without_live_promos(html.to_s)
        legacy = CATALOG_LEGACY_SCOPE.match(html)
        return html[legacy.begin(0)..] if legacy

        live = CATALOG_LIVE_SCOPE.match(html)
        return html[live.begin(0)..] if live

        html
      end

      def self.without_live_promos(html)
        LIVE_PROMO_STRIP.reduce(html) { |doc, pattern| doc.gsub(pattern, "") }
      end
      private_class_method :item_from_li, :strip_tags, :catalog_scope, :without_live_promos
    end
  end
end
