require "fileutils"

module NovelTrans
  class BookTranslate
    def initialize(book_id:, force: false, agent: CursorAgent.new)
      @book_id = book_id.to_s
      @force = force
      @agent = agent
    end

    def run
      rows = ChapterWork.list(@book_id)
      raise Error, "no ledger rows for book #{@book_id}. fetch first." if rows.empty?

      rows.each { |row| translate_row(row) }
    end

    private

    def translate_row(row)
      unless translatable?(row)
        puts "skip #{row.chapter_id}" if skip?(row)
        return
      end

      raw = NovelTrans.raw_path(@book_id, row.chapter_id)
      unless File.file?(raw)
        puts "failed #{row.chapter_id} (missing raw file)"
        return
      end

      begin
        vietnamese = @agent.translate(File.read(raw))
      rescue Error => e
        puts "failed #{row.chapter_id} (#{e.message})"
        return
      end

      path = NovelTrans.vi_path(@book_id, row.chapter_id)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "#{vietnamese}\n")
      ChapterWork.new(book_id: @book_id, chapter_id: row.chapter_id, status: "translated").save
      puts "translated #{row.chapter_id}"
    end

    def translatable?(row)
      return true if row.status == "fetched"
      return true if @force && %w[translated uploaded].include?(row.status)

      false
    end

    def skip?(row)
      return false if @force

      %w[translated uploaded].include?(row.status)
    end
  end
end
