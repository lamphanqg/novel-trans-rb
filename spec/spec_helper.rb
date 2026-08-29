require "tmpdir"

require_relative "../lib/novel_trans"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around do |example|
    Dir.mktmpdir("novel-trans-spec-") do |dir|
      NovelTrans.root = dir
      example.run
    end
    NovelTrans.root = nil
  end
end
