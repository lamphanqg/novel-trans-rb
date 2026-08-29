require "fileutils"

RSpec.describe NovelTrans::Qidian::ChapterPersist do
  let(:book_id) { "1036645930" }
  let(:chapter_id) { "747314648" }
  let(:persist) { described_class.new(book_id:) }

  def result(verdict, title: "第一章", body: "城门外")
    NovelTrans::Qidian::ChapterPage::Result.new(title:, body:, verdict:)
  end

  def write_fetched
    path = NovelTrans.raw_path(book_id, chapter_id)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "ok\n")
    NovelTrans::ChapterWork.new(book_id:, chapter_id:, status: "fetched").save
  end

  it "does not skip when nothing is on disk" do
    expect(persist.skip?(chapter_id)).to be(false)
  end

  it "skips a chapter that is already fetched" do
    write_fetched
    expect(persist.skip?(chapter_id)).to be(true)
  end

  it "does not skip a fetched chapter when force is set" do
    write_fetched
    expect(described_class.new(book_id:, force: true).skip?(chapter_id)).to be(false)
  end

  it "does not skip when the ledger is not fetched" do
    write_fetched
    NovelTrans::ChapterWork.new(book_id:, chapter_id:, status: "failed").save
    expect(persist.skip?(chapter_id)).to be(false)
  end

  it "writes raw text and fetched ledger for an ok result" do
    expect { persist.apply_result(result(:ok), chapter_id) }.to output(/fetched #{chapter_id}/).to_stdout
    expect(File.read(NovelTrans.raw_path(book_id, chapter_id))).to include("第一章", "城门外")
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("fetched")
  end

  it "sets locked and removes a raw file" do
    write_fetched
    expect { persist.apply_result(result(:locked), chapter_id) }.to output(/locked #{chapter_id}/).to_stdout
    expect(File).not_to exist(NovelTrans.raw_path(book_id, chapter_id))
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("locked")
  end

  it "sets failed for PUA and does not keep the body" do
    expect { persist.apply_result(result(:pua, body: "\u{E000}"), chapter_id) }
      .to output(/pua_font #{chapter_id}/).to_stdout
    expect(File).not_to exist(NovelTrans.raw_path(book_id, chapter_id))
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("failed")
  end

  it "sets failed for a blocked page and tells the operator to use qidian-chrome" do
    expect { persist.apply_result(result(:blocked), chapter_id) }
      .to output(/refused to render.*qidian-chrome/m).to_stdout
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("failed")
  end

  it "sets failed when there is no chapter body" do
    expect { persist.apply_result(result(:empty, body: ""), chapter_id) }
      .to output(/no chapter body/).to_stdout
    expect(File).not_to exist(NovelTrans.raw_path(book_id, chapter_id))
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("failed")
  end
end
