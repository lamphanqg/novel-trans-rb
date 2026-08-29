require "fileutils"

module NovelTrans
  module Qidian
    class BookFetch
      def initialize(book_id:, force: false, html_file: nil, chapter_id: nil)
        @book_id = book_id.to_s
        @force = force
        @html_file = html_file
        @chapter_id = chapter_id
      end

      def run
        raise ArgumentError, "--html-file is required" if @html_file.to_s.empty?

        apply_html(File.read(@html_file), chapter_id: required_chapter_id)
      end

      def apply_html(html, chapter_id:)
        if skip?(chapter_id)
          puts "skip #{chapter_id}"
          return
        end

        apply_result(ChapterPage.parse(html, chapter_id:), chapter_id)
      end

      private

      def required_chapter_id
        raise ArgumentError, "--chapter-id is required with --html-file" if @chapter_id.to_s.empty?

        @chapter_id.to_s
      end

      def skip?(chapter_id)
        return false if @force

        path = NovelTrans.raw_path(@book_id, chapter_id)
        return false unless File.file?(path)
        return false unless File.file?(ChapterWork.ledger_path(@book_id, chapter_id))

        ChapterWork.load(@book_id, chapter_id).status == "fetched"
      end

      def apply_result(result, chapter_id)
        case result.verdict
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
        else
          write_ledger(chapter_id, "failed")
          FileUtils.rm_f(NovelTrans.raw_path(@book_id, chapter_id))
          puts "failed #{chapter_id} (no chapter body in the DOM)"
        end
      end

      def write_ledger(chapter_id, status)
        ChapterWork.new(book_id: @book_id, chapter_id:, status:).save
      end
    end
  end
end
