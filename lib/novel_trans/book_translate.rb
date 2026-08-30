require "fileutils"

module NovelTrans
  class BookTranslate
    def initialize(book_id:, force: false, agent: CursorAgent.new)
      @book_id = book_id.to_s
      @force = force
      @agent = agent
      @names = Vocab.load(@book_id)
    end

    def run
      rows = ChapterWork.list(@book_id)
      raise Error, "no ledger rows for book #{@book_id}. fetch first." if rows.empty?

      rows = rows.sort_by { |row| row.chapter_id.to_i }
      if (limit = ENV.fetch("NOVEL_TRANS_CHAPTER_LIMIT", nil))
        n = Integer(limit)
        rows = rows.first(n)
        puts "limit #{n} chapters (NOVEL_TRANS_CHAPTER_LIMIT)"
      end

      rows.each { |row| process_row(row) }
    end

    private

    def process_row(row)
      if translatable?(row)
        translate_row(row)
      else
        puts "skip #{row.chapter_id}" if skip?(row)
        harvest_row(row) if pair?(row)
      end
    end

    def harvest_row(row)
      extracted = @agent.extract_names(
        File.read(NovelTrans.raw_path(@book_id, row.chapter_id)),
        File.read(NovelTrans.vi_path(@book_id, row.chapter_id)),
        locked: @names
      )
      apply_names(row.chapter_id, extracted)
    rescue Error => e
      puts "failed #{row.chapter_id} (#{e.message})"
    end

    def pair?(row)
      File.file?(NovelTrans.raw_path(@book_id, row.chapter_id)) &&
        File.file?(NovelTrans.vi_path(@book_id, row.chapter_id))
    end

    def translate_row(row)
      raw = NovelTrans.raw_path(@book_id, row.chapter_id)
      unless File.file?(raw)
        puts "failed #{row.chapter_id} (missing raw file)"
        return
      end

      begin
        vietnamese, extracted = @agent.translate_with_names(File.read(raw), names: @names)
      rescue Error => e
        puts "failed #{row.chapter_id} (#{e.message})"
        return
      end

      path = NovelTrans.vi_path(@book_id, row.chapter_id)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "#{vietnamese}\n")
      ChapterWork.new(book_id: @book_id, chapter_id: row.chapter_id, status: "translated").save
      puts "translated #{row.chapter_id}"
      apply_names(row.chapter_id, extracted)
    end

    def apply_names(chapter_id, extracted)
      added = Vocab.merge(@book_id, extracted)
      @names = Vocab.load(@book_id)
      puts "vocab #{chapter_id} +#{added}"
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
