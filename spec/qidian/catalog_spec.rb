RSpec.describe NovelTrans::Qidian::Catalog do
  it "parses book_id and chapter_id from a chapter URL" do
    ids = described_class.parse_chapter_url("https://www.qidian.com/chapter/1036645930/747314648/")
    expect(ids).to eq(book_id: "1036645930", chapter_id: "747314648")
  end
end
