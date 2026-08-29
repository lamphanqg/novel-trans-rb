module NovelTrans
  module Qidian
    class Catalog
      CHAPTER_PATH = %r{/chapter/(\d+)/(\d+)/?}

      def self.parse_chapter_url(url)
        match = CHAPTER_PATH.match(url.to_s)
        raise ArgumentError, "not a Qidian chapter URL: #{url}" unless match

        { book_id: match[1], chapter_id: match[2] }
      end
    end
  end
end
