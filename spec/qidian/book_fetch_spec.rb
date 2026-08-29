RSpec.describe NovelTrans::Qidian::BookFetch do
  let(:book_id) { "1036645930" }
  let(:chapter_id) { "747314648" }
  let(:fixtures) { File.expand_path("../fixtures/qidian", __dir__) }

  def fetch(name, force: false)
    described_class.new(
      book_id: book_id,
      force: force,
      html_file: File.join(fixtures, name),
      chapter_id: chapter_id
    ).run
  end

  it "writes raw text and fetched ledger for unlocked HTML" do
    expect { fetch("chapter_unlocked.html") }.to output(/fetched #{chapter_id}/).to_stdout
    raw = File.read(NovelTrans.raw_path(book_id, chapter_id))
    expect(raw).to include("第一章 开场")
    expect(raw).to include("城门外")
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("fetched")
  end

  it "skips a second fetch without --force" do
    expect { fetch("chapter_unlocked.html") }.to output(/fetched/).to_stdout
    expect { fetch("chapter_unlocked.html") }.to output(/skip #{chapter_id}/).to_stdout
  end

  it "rewrites when forced" do
    expect { fetch("chapter_unlocked.html") }.to output(/fetched/).to_stdout
    expect { fetch("chapter_unlocked.html", force: true) }.to output(/fetched #{chapter_id}/).to_stdout
  end

  it "sets locked and does not keep a raw file" do
    expect { fetch("chapter_locked.html") }.to output(/locked #{chapter_id}/).to_stdout
    expect(File).not_to exist(NovelTrans.raw_path(book_id, chapter_id))
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("locked")
  end

  it "sets failed for PUA and does not store the glyphs" do
    expect { fetch("chapter_pua.html") }.to output(/pua_font #{chapter_id}/).to_stdout
    expect(File).not_to exist(NovelTrans.raw_path(book_id, chapter_id))
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("failed")
  end

  it "sets failed when the page is only Qidian chrome" do
    expect { fetch("chapter_chrome.html") }.to output(/failed #{chapter_id}/).to_stdout
    expect(File).not_to exist(NovelTrans.raw_path(book_id, chapter_id))
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("failed")
  end

  it "sets failed when Qidian shows 章节加载失败" do
    expect { fetch("chapter_blocked.html") }.to output(/refused to render/).to_stdout
    expect(NovelTrans::ChapterWork.load(book_id, chapter_id).status).to eq("failed")
  end

  it "rejects a chapter URL from another book before opening a browser" do
    expect do
      described_class.new(
        book_id: book_id,
        urls: ["https://www.qidian.com/chapter/1/2/"]
      ).run
    end.to raise_error(ArgumentError, /does not match --book/)
  end
end
