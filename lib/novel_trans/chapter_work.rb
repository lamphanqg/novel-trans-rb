require "fileutils"
require "json"

module NovelTrans
  class ChapterWork
    STATUSES = %w[pending locked fetched translated uploaded failed].freeze

    attr_reader :book_id, :chapter_id, :status

    def self.ledger_path(book_id, chapter_id)
      File.join(NovelTrans.ledger_root, book_id.to_s, "#{chapter_id}.json")
    end

    def self.load(book_id, chapter_id)
      path = ledger_path(book_id, chapter_id)
      raise Errno::ENOENT, path unless File.file?(path)

      data = JSON.parse(File.read(path))
      new(
        book_id: data.fetch("book_id"),
        chapter_id: data.fetch("chapter_id"),
        status: data.fetch("status")
      )
    end

    def self.list(book_id)
      dir = File.join(NovelTrans.ledger_root, book_id.to_s)
      return [] unless File.directory?(dir)

      Dir.glob(File.join(dir, "*.json")).map do |path|
        load(book_id, File.basename(path, ".json"))
      end
    end

    def initialize(book_id:, chapter_id:, status: "pending")
      @book_id = book_id.to_s
      @chapter_id = chapter_id.to_s
      @status = status.to_s
      assert_status!(@status)
    end

    def path
      self.class.ledger_path(@book_id, @chapter_id)
    end

    def save
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, JSON.pretty_generate(as_json))
      self
    end

    def as_json
      {
        "book_id" => @book_id,
        "chapter_id" => @chapter_id,
        "status" => @status
      }
    end

    private

    def assert_status!(value)
      return if STATUSES.include?(value)

      raise ArgumentError, "unknown status #{value}"
    end
  end
end
