RSpec.describe NovelTrans::Qidian::Session do
  it "reads chapter_id from a tab URL" do
    id = described_class.chapter_id_from_url("https://www.qidian.com/chapter/1016572786/514924883/")
    expect(id).to eq("514924883")
  end

  it "returns nil for a non-chapter URL" do
    expect(described_class.chapter_id_from_url("https://www.qidian.com/")).to be_nil
  end

  it "maps a CDP handshake failure to qidian-chrome" do
    playwright = double("playwright")
    chromium = double("chromium")
    allow(Playwright).to receive(:create).and_yield(playwright)
    allow(playwright).to receive(:chromium).and_return(chromium)
    allow(chromium).to receive(:connect_over_cdp)
      .with(described_class::CDP_ENDPOINT)
      .and_raise(Playwright::Error.new(message: "connect ECONNREFUSED"))

    expect { described_class.connect { nil } }
      .to raise_error(NovelTrans::Error, /qidian-chrome/)
  end
end
