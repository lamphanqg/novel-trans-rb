require "fileutils"

module NovelTrans
  module Qidian
    class ChapterPersist
      def initialize(book_id:, force: false)
        @book_id = book_id.to_s
        @force = force
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
          drop_raw(chapter_id, "locked", "locked #{chapter_id}")
        when :pua
          drop_raw(chapter_id, "failed", "pua_font #{chapter_id}")
        when :ok
          path = NovelTrans.raw_path(@book_id, chapter_id)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, "#{result.title}\n\n#{result.body}\n")
          write_ledger(chapter_id, "fetched")
          puts "fetched #{chapter_id}"
        when :blocked
          drop_raw(chapter_id, "failed", "failed #{chapter_id} (Qidian refused to render the chapter in this browser)")
          puts "Start bin/qidian-chrome, log in there, then fetch again with --force"
        else
          drop_raw(chapter_id, "failed", "failed #{chapter_id} (no chapter body in the DOM)")
        end
      end

      private

      def write_ledger(chapter_id, status)
        ChapterWork.new(book_id: @book_id, chapter_id:, status:).save
      end

      def drop_raw(chapter_id, status, message)
        write_ledger(chapter_id, status)
        FileUtils.rm_f(NovelTrans.raw_path(@book_id, chapter_id))
        puts message
      end
    end
  end
end
