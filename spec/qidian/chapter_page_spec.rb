RSpec.describe NovelTrans::Qidian::ChapterPage do
  let(:fixtures) { File.expand_path("../fixtures/qidian", __dir__) }

  def parse(name, chapter_id: "747314648")
    html = File.read(File.join(fixtures, name))
    described_class.parse(html, chapter_id:)
  end

  it "reads Qidian content-text spans and drops paragraph reviews" do
    result = parse("chapter_spans.html", chapter_id: "514924883")
    expect(result.verdict).to eq(:ok)
    expect(result.title).to eq("第二百五十六章 套路现场教学")
    expect(result.body).to include("金蝉子此时来寻")
    expect(result.body).not_to include("2")
    expect(result.title).not_to include("30")
  end

  it "reads title and body from unlocked HTML" do
    result = parse("chapter_unlocked.html")
    expect(result.verdict).to eq(:ok)
    expect(result.title).to eq("第一章 开场")
    expect(result.body.length).to be > 20
    expect(result.body).to include("城门外")
  end

  it "flags PUA text" do
    result = parse("chapter_pua.html")
    expect(result.verdict).to eq(:pua)
    expect(result.body).to eq("")
  end

  it "marks the VIP subscribe banner as locked" do
    result = parse("chapter_locked.html")
    expect(result.verdict).to eq(:locked)
    expect(result.body).to eq("")
  end

  it "does not treat Qidian UI labels as a chapter body" do
    result = parse("chapter_chrome.html", chapter_id: "514924883")
    expect(result.verdict).to eq(:empty)
    expect(result.body).to eq("")
  end

  it "marks 章节加载失败 as blocked" do
    result = parse("chapter_blocked.html")
    expect(result.verdict).to eq(:blocked)
  end
end
