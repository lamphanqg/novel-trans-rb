RSpec.describe NovelTrans::Qidian::Session do
  it "reads chapter_id from a tab URL" do
    id = described_class.chapter_id_from_url("https://www.qidian.com/chapter/1016572786/514924883/")
    expect(id).to eq("514924883")
  end

  it "returns nil for a non-chapter URL" do
    expect(described_class.chapter_id_from_url("https://www.qidian.com/")).to be_nil
  end
end
