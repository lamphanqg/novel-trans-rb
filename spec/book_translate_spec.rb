require "fileutils"

RSpec.describe NovelTrans::BookTranslate do
  let(:book_id) { "1036645930" }
  let(:chapter_id) { "747314648" }
  let(:agent) { instance_double(NovelTrans::CursorAgent) }

  def seed(chapter_id, status:, body: "第一章\n\n城门外")
    if body
      path = NovelTrans.raw_path(book_id, chapter_id)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, body)
    end
    NovelTrans::ChapterWork.new(book_id:, chapter_id:, status:).save
  end

  def write_vi(chapter_id, text)
    path = NovelTrans.vi_path(book_id, chapter_id)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, text)
  end

  def translate
    described_class.new(book_id:, agent:).run
  end

  it "writes Vietnamese text and translated ledger for a fetched chapter" do
    seed(chapter_id, status: "fetched")
    allow(agent).to receive(:translate_with_names).and_return(["Chương 1\n\nNgoài cửa thành", {}])
    expect { translate }.to output(/translated #{chapter_id}/).to_stdout
    expect(File.read(NovelTrans.vi_path(book_id, chapter_id))).to include("Ngoài cửa thành")
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("translated")
  end

  it "skips an already translated chapter without --force" do
    seed(chapter_id, status: "translated")
    expect(agent).not_to receive(:translate_with_names)
    expect { translate }.to output(/skip #{chapter_id}/).to_stdout
  end

  it "skips an uploaded chapter without --force" do
    seed(chapter_id, status: "uploaded")
    expect(agent).not_to receive(:translate_with_names)
    expect { translate }.to output(/skip #{chapter_id}/).to_stdout
  end

  it "rewrites a translated chapter when forced" do
    seed(chapter_id, status: "translated")
    allow(agent).to receive(:translate_with_names).and_return(["bản mới", {}])
    expect { described_class.new(book_id:, force: true, agent:).run }
      .to output(/translated #{chapter_id}/).to_stdout
    expect(File.read(NovelTrans.vi_path(book_id, chapter_id))).to include("bản mới")
  end

  it "does not call the agent for locked or failed rows" do
    seed("1", status: "locked")
    seed("2", status: "failed")
    expect(agent).not_to receive(:translate_with_names)
    expect(agent).not_to receive(:extract_names)
    expect { translate }.not_to output(/skip/).to_stdout
  end

  it "leaves fetched status when the agent fails" do
    seed(chapter_id, status: "fetched")
    allow(agent).to receive(:translate_with_names).and_raise(NovelTrans::Error, "cursor agent failed")
    expect { translate }.to output(/failed #{chapter_id}/).to_stdout
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("fetched")
    expect(File).not_to exist(NovelTrans.vi_path(book_id, chapter_id))
  end

  it "does not call the agent when the raw file is missing" do
    seed(chapter_id, status: "fetched", body: nil)
    expect(agent).not_to receive(:translate_with_names)
    expect { translate }.to output(/missing raw file/).to_stdout
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("fetched")
  end

  it "requires a ledger for the book" do
    expect { translate }.to raise_error(NovelTrans::Error, /fetch first/)
  end

  it "passes vocab names to the agent" do
    seed(chapter_id, status: "fetched", body: "皖江雨来了")
    path = NovelTrans.vocab_path(book_id)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "皖江雨: Hoàn Giang Vũ\n")
    expect(agent).to receive(:translate_with_names)
      .with("皖江雨来了", names: { "皖江雨" => "Hoàn Giang Vũ" })
      .and_return(["Hoàn Giang Vũ đến.", {}])
    expect { translate }.to output(/translated/).to_stdout
  end

  it "harvests names from skipped translated chapters without rewriting Vietnamese" do
    seed(chapter_id, status: "translated", body: "皖江雨来了")
    write_vi(chapter_id, "Hoàn Giang Vũ đến.")
    expect(agent).to receive(:extract_names)
      .with("皖江雨来了", "Hoàn Giang Vũ đến.", locked: {})
      .and_return("皖江雨" => "Hoàn Giang Vũ")
    expect(agent).not_to receive(:translate_with_names)
    expect { translate }.to output(/vocab #{chapter_id} \+1/).to_stdout
    expect(File.read(NovelTrans.vi_path(book_id, chapter_id))).to eq("Hoàn Giang Vũ đến.")
    expect(NovelTrans::Vocab.load(book_id)).to eq("皖江雨" => "Hoàn Giang Vũ")
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("translated")
  end

  it "translates Vietnamese and names in one call" do
    seed(chapter_id, status: "fetched", body: "皖江雨来了")
    expect(agent).to receive(:translate_with_names)
      .with("皖江雨来了", names: {})
      .and_return(["Hoàn Giang Vũ đến.", { "皖江雨" => "Hoàn Giang Vũ" }])
    expect(agent).not_to receive(:extract_names)
    expect { translate }.to output(/translated #{chapter_id}/).to_stdout
    expect(NovelTrans::Vocab.load(book_id)).to eq("皖江雨" => "Hoàn Giang Vũ")
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("translated")
  end

  it "feeds named translations into the next chapter's prompt" do
    seed("1", status: "fetched", body: "皖江雨来了")
    seed("2", status: "fetched", body: "李长寿来了")
    allow(NovelTrans::ChapterWork).to receive(:list).and_return(
      [
        NovelTrans::ChapterWork.load(book_id, "1"),
        NovelTrans::ChapterWork.load(book_id, "2")
      ]
    )
    expect(agent).to receive(:translate_with_names)
      .with("皖江雨来了", names: {})
      .and_return(["Hoàn Giang Vũ đến.", { "皖江雨" => "Hoàn Giang Vũ" }])
    expect(agent).to receive(:translate_with_names)
      .with("李长寿来了", names: { "皖江雨" => "Hoàn Giang Vũ" })
      .and_return(["Lý Trường Thọ đến.", {}])
    expect(agent).not_to receive(:extract_names)
    expect { translate }.to output(/translated 1/).to_stdout
  end
end
