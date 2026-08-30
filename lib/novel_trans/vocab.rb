require "yaml"

module NovelTrans
  class Vocab
    def self.path(book_id)
      NovelTrans.vocab_path(book_id)
    end

    def self.load(book_id)
      file = path(book_id)
      return {} unless File.file?(file)

      data = YAML.safe_load_file(file, aliases: false)
      return {} if data.nil?
      raise Error, "vocab #{file} must be a mapping of Chinese names to Vietnamese" unless data.is_a?(Hash)

      data.each_with_object({}) do |(chinese, vietnamese), names|
        next if chinese.to_s.empty? || vietnamese.to_s.empty?

        names[chinese.to_s] = vietnamese.to_s
      end
    end
  end
end
