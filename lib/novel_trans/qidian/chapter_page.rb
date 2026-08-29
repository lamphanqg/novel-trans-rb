module NovelTrans
  module Qidian
    class ChapterPage
      PUA = /[\u{E000}-\u{F8FF}]/
      PUA_RATIO = 0.05
      LOCK_MARKERS = %w[这是VIP章节 订阅本章].freeze
      LOCK_CLASSES = %w[lock-chapter vip-tips chapter-buy-tips buy-chapter-wrap].freeze
      CHROME_LINE = /
        \A(
          Untitled|旧版|反馈|目录|书详情|加书架|投票|夜间|设置|客户端|在书架|回书架|
          扫码下载.*|新设备.*免费读
        )\z
      /x
      EXTRACT_JS = <<~JS.freeze
        (chapterId) => {
          const bodyText = document.body ? document.body.innerText : "";
          const lockSels = [".lock-chapter", ".vip-tips", ".chapter-buy-tips", ".buy-chapter-wrap"];
          const locked = bodyText.includes("这是VIP章节") || bodyText.includes("订阅本章") ||
            lockSels.some((sel) => document.querySelector(sel));
          const titleEl = document.querySelector("h1.j_chapterName, h1.chapter-name, .chapter-name, h1");
          let title = "Untitled";
          if (titleEl) {
            const clone = titleEl.cloneNode(true);
            clone.querySelectorAll(".review").forEach((n) => n.remove());
            title = clone.innerText.replace(/\\s+/g, " ").trim() || "Untitled";
          }
          if (bodyText.includes("章节加载失败")) return { title, body: "", locked: false, loadFailed: true };
          if (locked) return { title, body: "", locked: true };
          const selectors = [];
          if (chapterId) selectors.push("#c-" + chapterId);
          selectors.push("main.content", "main[id^='c-']", ".read-content", ".chapter-content");
          let container = null;
          for (const sel of selectors) {
            container = document.querySelector(sel);
            if (container) break;
          }
          if (!container) return { title, body: "", locked: false };
          const fromSpans = Array.from(container.querySelectorAll("span.content-text"))
            .map((n) => n.textContent.trim())
            .filter((t) => t.length > 0);
          const fromParas = Array.from(container.querySelectorAll("p")).map((p) => {
            const clone = p.cloneNode(true);
            clone.querySelectorAll(".review, i, em, a").forEach((n) => n.remove());
            return clone.textContent.trim();
          }).filter((t) => t.length > 0);
          const body = (fromSpans.length > 0 ? fromSpans : fromParas).join(String.fromCharCode(10));
          return { title, body, locked: false };
        }
      JS

      Result = Struct.new(:title, :body, :outcome, keyword_init: true)

      def self.parse(html, chapter_id: nil)
        html = html.to_s
        title = strip_tags(drop_reviews(first_match(html, %r{<h1\b[^>]*>(.*?)</h1>}im) || "Untitled"))
        return Result.new(title: title, body: "", outcome: :locked) if locked?(html)
        return Result.new(title: title, body: "", outcome: :blocked) if html.include?("章节加载失败")

        finish(title, extract_body(html, chapter_id))
      end

      def self.from_page(page, chapter_id:)
        data = page.evaluate(EXTRACT_JS, arg: chapter_id)
        title = (data["title"] || data[:title]).to_s
        body = (data["body"] || data[:body]).to_s
        locked = data["locked"] || data[:locked]
        load_failed = data["loadFailed"] || data[:loadFailed]
        return Result.new(title: title, body: "", outcome: :locked) if locked
        return Result.new(title: title, body: "", outcome: :blocked) if load_failed

        finish(title, body)
      end

      def self.finish(title, body)
        body = clean(body)
        return Result.new(title: title, body: "", outcome: :pua) if pua?(body)
        return Result.new(title: title, body: "", outcome: :empty) if body.length <= 20

        Result.new(title: title, body: body, outcome: :ok)
      end

      def self.locked?(html)
        LOCK_MARKERS.any? { |mark| html.include?(mark) } ||
          LOCK_CLASSES.any? { |name| html.include?(name) }
      end

      def self.pua?(text)
        return false if text.empty?

        (text.scan(PUA).size.to_f / text.length) > PUA_RATIO
      end

      def self.extract_body(html, chapter_id)
        chunk = drop_reviews(inner_by_chapter_id(html, chapter_id))
        from_id = paragraphs(chunk)
        return from_id unless from_id.empty?

        paragraphs(drop_reviews(html[%r{<main\b[^>]*>(.*?)</main>}im, 1]))
      end

      def self.drop_reviews(chunk)
        text = chunk.to_s
        loop do
          next_text = text.gsub(%r{<span\b[^>]*class=["'][^"']*review[^"']*["'][^>]*>((?!<span).)*?</span>}im, "")
          break if next_text == text

          text = next_text
        end
        text
      end

      def self.inner_by_chapter_id(html, chapter_id)
        return if chapter_id.to_s.empty?

        html[%r{<[^>]+id=["']c-#{Regexp.escape(chapter_id)}["'][^>]*>(.*?)</(?:main|div)>}im, 1]
      end

      def self.paragraphs(chunk)
        return "" if chunk.nil?

        chunk.scan(%r{<p\b[^>]*>(.*?)</p>}im).flatten.map do |inner|
          strip_tags(inner).strip
        end.reject(&:empty?).join("\n")
      end

      def self.clean(text)
        lines = text.to_s.split("\n").filter_map do |line|
          stripped = line.strip
          next if stripped.empty? || stripped.match?(CHROME_LINE)

          stripped
        end
        joined = lines.join("\n")
        joined.gsub(/[①-⑳⑴-⒇]/, "").gsub(/^本作品由起点中文网.*$/, "").gsub(/^书友\d+.*$/, "").gsub(/\n{3,}/, "\n\n").strip
      end

      def self.strip_tags(text)
        text.to_s.gsub(/<[^>]+>/, "").gsub("&nbsp;", " ").strip
      end

      def self.first_match(html, regex)
        html[regex, 1]
      end
    end
  end
end
