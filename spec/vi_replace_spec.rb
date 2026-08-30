require "fileutils"

RSpec.describe NovelTrans::ViReplace do
  let(:book_id) { "1016572786" }

  def write_vi(chapter_id, text)
    path = NovelTrans.vi_path(book_id, chapter_id)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, text)
  end

  it "rewrites the old string in every Vietnamese file for the book" do
    write_vi("514073876", "Sư bá Oản Giang Vũ thảm tử.\n")
    write_vi("514110262", "lo lắng cho việc của Hoàn Giang Vũ...\n")
    expect do
      described_class.new(book_id:, old: "Oản Giang Vũ", new: "Hoàn Giang Vũ").run
    end.to output(/514073876 1/).to_stdout
    expect(File.read(NovelTrans.vi_path(book_id, "514073876"))).to include("Hoàn Giang Vũ")
    expect(File.read(NovelTrans.vi_path(book_id, "514073876"))).not_to include("Oản Giang Vũ")
    expect(File.read(NovelTrans.vi_path(book_id, "514110262"))).to include("Hoàn Giang Vũ")
  end

  it "rejects an empty --old" do
    expect { described_class.new(book_id:, old: "", new: "Hoàn Giang Vũ").run }
      .to raise_error(ArgumentError, /old/)
  end
end
