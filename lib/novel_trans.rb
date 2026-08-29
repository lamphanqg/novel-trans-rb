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
  end
end

require_relative "novel_trans/chapter_work"
require_relative "novel_trans/cli"
