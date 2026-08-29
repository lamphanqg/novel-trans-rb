module NovelTrans
  class Error < StandardError; end
  class NotImplementedCommand < Error; end

  class << self
    attr_writer :root

    def root
      @root || File.expand_path("..", __dir__)
    end

    def ledger_root
      File.join(root, "var", "ledger")
    end

    def raw_path(book_id, chapter_id)
      File.join(root, "input", "raw", book_id.to_s, "#{chapter_id}.txt")
    end
  end
end

require_relative "novel_trans/chapter_work"
require_relative "novel_trans/qidian"
require_relative "novel_trans/cli"
