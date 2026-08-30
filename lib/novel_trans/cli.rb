require "fileutils"
require "thor"

module NovelTrans
  class CLI < Thor
    package_name "novel-trans"

    def self.exit_on_failure?
      true
    end

    desc "status", "Print ledger counts for a book, or matching rows with --status"
    option :book, type: :string, required: true
    option :status, type: :string, required: false
    def status
      FileUtils.mkdir_p(NovelTrans.ledger_root)
      book_id = options[:book]
      rows = ChapterWork.list(book_id)

      if options[:status]
        print_status_rows(rows, options[:status])
      else
        print_status_counts(rows)
      end
    end

    desc "login", "Save a Qidian Playwright session"
    def login
      not_built("login")
    end

    desc "fetch", "Download catalog chapters, or only --url chapters, from Qidian"
    option :book, type: :string, required: true
    option :force, type: :boolean, default: false
    option :html_file, type: :string
    option :chapter_id, type: :string
    option :url, type: :string, repeatable: true
    def fetch
      Qidian::BookFetch.new(
        book_id: options[:book],
        force: options[:force],
        html_file: options[:html_file],
        chapter_id: options[:chapter_id],
        urls: Array(options[:url])
      ).run
    end

    desc "translate", "Translate fetched chapters to Vietnamese with cursor agent"
    option :book, type: :string, required: true
    option :force, type: :boolean, default: false
    def translate
      BookTranslate.new(book_id: options[:book], force: options[:force]).run
    end

    desc "upload", "Put a book's Vietnamese files on R2"
    def upload
      not_built("upload")
    end

    desc "pipeline", "run: fetch, translate, upload a book, then rebuild the reader"
    map "run" => :pipeline
    def pipeline
      not_built("run")
    end

    desc "site", "Build static HTML and upload www/"
    def site
      not_built("site")
    end

    no_commands do
      def not_built(name)
        raise NotImplementedCommand, "#{name} is not implemented yet"
      end

      def print_status_counts(rows)
        tally = rows.map(&:status).tally
        puts "status\tcount"
        ChapterWork::STATUSES.each do |name|
          puts [name, tally.fetch(name, 0)].join("\t")
        end
        puts ["total", rows.size].join("\t")
      end

      def print_status_rows(rows, status)
        raise ArgumentError, "unknown status #{status}" unless ChapterWork::STATUSES.include?(status)

        puts "book_id\tchapter_id\tstatus"
        rows.select { |row| row.status == status }.each do |row|
          puts [row.book_id, row.chapter_id, row.status].join("\t")
        end
      end
    end
  end
end
