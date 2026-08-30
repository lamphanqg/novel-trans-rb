require "fileutils"
require "yaml"

RSpec.describe NovelTrans::Vocab do
  let(:book_id) { "1016572786" }

  def write_vocab(text)
    path = described_class.path(book_id)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, text)
  end

  it "returns an empty hash when the file is missing" do
    expect(described_class.load(book_id)).to eq({})
  end

  it "loads Chinese to Vietnamese pairs" do
    write_vocab("皖江雨: Hoàn Giang Vũ\n李长寿: Lý Trường Thọ\n")
    expect(described_class.load(book_id)).to eq(
      "皖江雨" => "Hoàn Giang Vũ",
      "李长寿" => "Lý Trường Thọ"
    )
  end

  it "rejects a vocab file that is not a mapping" do
    write_vocab("- just a list\n")
    expect { described_class.load(book_id) }.to raise_error(NovelTrans::Error, /mapping/)
  end

  it "parses a fenced YAML mapping from the agent" do
    expect(described_class.parse("```yaml\n皖江雨: Hoàn Giang Vũ\n```\n")).to eq(
      "皖江雨" => "Hoàn Giang Vũ"
    )
  end

  it "adds new names and keeps locked readings" do
    write_vocab("皖江雨: Hoàn Giang Vũ\n")
    added = described_class.merge(
      book_id,
      "皖江雨" => "Oản Giang Vũ",
      "李长寿" => "Lý Trường Thọ"
    )
    expect(added).to eq(1)
    expect(described_class.load(book_id)).to eq(
      "皖江雨" => "Hoàn Giang Vũ",
      "李长寿" => "Lý Trường Thọ"
    )
  end
end
