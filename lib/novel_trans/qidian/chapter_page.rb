module NovelTrans
  module Qidian
    class ChapterPage
      # Qidian sometimes paints VIP text with Private Use Area glyphs instead of real characters.
      PUA = /[\u{E000}-\u{F8FF}]/
      PUA_RATIO = 0.05
      LOCK_MARKERS = %w[这是VIP章节 订阅本章].freeze
      LOCK_CLASSES = %w[lock-chapter vip-tips chapter-buy-tips buy-chapter-wrap].freeze
      UI_NOISE_LINE = /
        \A(
          Untitled|旧版|反馈|目录|书详情|加书架|投票|夜间|设置|客户端|在书架|回书架|
          扫码下载.*|新设备.*免费读
        )\z
      /x

      Result = Struct.new(:title, :body, :verdict, keyword_init: true)

      def self.parse(html, chapter_id: nil)
        new(html, chapter_id:).result
      end

      def self.from_page(page, chapter_id:)
        new("", chapter_id:).result_from_dom(page.evaluate(extract_js, arg: chapter_id))
      end

      def initialize(html, chapter_id: nil)
        @html = html.to_s
        @chapter_id = chapter_id
      end

      def result
        title = strip_tags(drop_reviews(first_match(%r{<h1\b[^>]*>(.*?)</h1>}im) || "Untitled"))
        return Result.new(title:, body: "", verdict: :locked) if locked?
        return Result.new(title:, body: "", verdict: :blocked) if @html.include?("章节加载失败")

        finish(title, extract_body)
      end

      def result_from_dom(data)
        data = data.to_h.transform_keys(&:to_s)
        title = data["title"].to_s
        body = data["body"].to_s
        return Result.new(title:, body: "", verdict: :locked) if data["locked"]
        return Result.new(title:, body: "", verdict: :blocked) if data["loadFailed"]

        finish(title, body)
      end

      private

      def finish(title, body)
        body = clean(body)
        return Result.new(title:, body: "", verdict: :pua) if pua?(body)
        return Result.new(title:, body: "", verdict: :empty) if body.length <= 20

        Result.new(title:, body:, verdict: :ok)
      end

      def locked?
        LOCK_MARKERS.any? { |mark| @html.include?(mark) } ||
          LOCK_CLASSES.any? { |name| @html.include?(name) }
      end

      def pua?(text)
        text.length.positive? && (text.scan(PUA).size.to_f / text.length) > PUA_RATIO
      end

      def extract_body
        from_id = paragraphs(drop_reviews(inner_by_chapter_id))
        return from_id unless from_id.empty?

        paragraphs(drop_reviews(@html[%r{<main\b[^>]*>(.*?)</main>}im, 1]))
      end

      def drop_reviews(chunk)
        text = chunk.to_s
        loop do
          next_text = text.gsub(%r{<span\b[^>]*class=["'][^"']*review[^"']*["'][^>]*>((?!<span).)*?</span>}im, "")
          break if next_text == text

          text = next_text
        end
        text
      end

      def inner_by_chapter_id
        return if @chapter_id.to_s.empty?

        @html[%r{<[^>]+id=["']c-#{Regexp.escape(@chapter_id.to_s)}["'][^>]*>(.*?)</(?:main|div)>}im, 1]
      end

      def paragraphs(chunk)
        return "" if chunk.nil?

        chunk.scan(%r{<p\b[^>]*>(.*?)</p>}im).flatten.map do |inner|
          strip_tags(inner).strip
        end.reject(&:empty?).join("\n")
      end

      def clean(text)
        lines = text.to_s.split("\n").filter_map do |line|
          stripped = line.strip
          next if stripped.empty? || stripped.match?(UI_NOISE_LINE)

          stripped
        end
        joined = lines.join("\n")
        joined.gsub(/[①-⑳⑴-⒇]/, "").gsub(/^本作品由起点中文网.*$/, "").gsub(/^书友\d+.*$/, "").gsub(/\n{3,}/, "\n\n").strip
      end

      def strip_tags(text)
        text.to_s.gsub(/<[^>]+>/, "").gsub("&nbsp;", " ").strip
      end

      def first_match(regex)
        @html[regex, 1]
      end

      def self.extract_js
        @extract_js ||= File.read(File.expand_path("extract_chapter.js", __dir__), encoding: "UTF-8")
      end
      private_class_method :extract_js
    end
  end
end
