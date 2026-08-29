RSpec.describe NovelTrans::Qidian::Catalog do
  it "parses open and VIP catalog rows" do
    html = File.read(File.expand_path("../fixtures/qidian/catalog.html", __dir__))
    items = described_class.parse(html)
    expect(items.size).to eq(2)
    expect(items[0].chapter_id).to eq("747314648")
    expect(items[0].vip).to eq(false)
    expect(items[1].chapter_id).to eq("747314649")
    expect(items[1].vip).to eq(true)
    expect(items[0].url).to include("/chapter/1036645930/747314648/")
  end

  it "parses book_id and chapter_id from a chapter URL" do
    ids = described_class.parse_chapter_url("https://www.qidian.com/chapter/1036645930/747314648/")
    expect(ids).to eq(book_id: "1036645930", chapter_id: "747314648")
  end
end
