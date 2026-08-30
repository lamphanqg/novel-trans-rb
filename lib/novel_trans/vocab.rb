require "fileutils"
require "yaml"

module NovelTrans
  class Vocab
    def self.path(book_id)
      NovelTrans.vocab_path(book_id)
    end

    def self.load(book_id)
      file = path(book_id)
      return {} unless File.file?(file)

      parse(File.read(file), source: file)
    end

    def self.parse(text, source: "vocab")
      body = strip_fences(text)
      data = YAML.safe_load(body, aliases: false)
      return {} if data.nil?
      raise Error, "#{source} must be a mapping of Chinese names to Vietnamese" unless data.is_a?(Hash)

      data.each_with_object({}) do |(chinese, vietnamese), names|
        next if chinese.to_s.empty? || vietnamese.to_s.empty?

        names[chinese.to_s] = vietnamese.to_s
      end
    end

    def self.merge(book_id, additions)
      names = load(book_id)
      added = 0
      additions.each do |chinese, vietnamese|
        chinese = chinese.to_s
        vietnamese = vietnamese.to_s
        next if chinese.empty? || vietnamese.empty?
        next if names.key?(chinese)

        names[chinese] = vietnamese
        added += 1
      end
      write(book_id, names) if added.positive?
      added
    end

    def self.write(book_id, names)
      file = path(book_id)
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, YAML.dump(names.sort.to_h))
    end

    def self.strip_fences(text)
      body = text.to_s.strip
      body = body.sub(/\A```(?:ya?ml)?\s*\n/i, "")
      body.sub(/\n```\s*\z/, "")
    end
    private_class_method :strip_fences
  end
end
