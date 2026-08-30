require "fileutils"

module NovelTrans
  class ViReplace
    def initialize(book_id:, old:, new:)
      @book_id = book_id.to_s
      @old = old.to_s
      @new = new.to_s
    end

    def run
      raise ArgumentError, "--old is required" if @old.empty?
      raise ArgumentError, "--new is required" if @new.empty?
      raise ArgumentError, "--old and --new are the same" if @old == @new

      files = Dir.glob(File.join(NovelTrans.vi_dir(@book_id), "*.txt"))
      changed = 0
      hits = 0
      files.each do |path|
        text = File.read(path)
        n = 0
        replaced = text.gsub(@old) do
          n += 1
          @new
        end
        next if n.zero?

        File.write(path, replaced)
        changed += 1
        hits += n
        puts "#{File.basename(path, '.txt')} #{n}"
      end
      puts "replaced #{hits} in #{changed} files"
    end
  end
end
