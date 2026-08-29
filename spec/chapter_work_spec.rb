RSpec.describe NovelTrans::ChapterWork do
  let(:book_id) { "1036645930" }
  let(:chap_a) { "747314648" }
  let(:chap_b) { "747314649" }

  it "rejects an unknown status without writing a ledger file" do
    expect do
      described_class.new(book_id: book_id, chapter_id: chap_a, status: "done")
    end.to raise_error(ArgumentError, /unknown status/)
    expect(File).not_to exist(described_class.ledger_path(book_id, chap_a))
  end

  it "writes one JSON file per chapter id" do
    described_class.new(book_id: book_id, chapter_id: chap_a).save
    described_class.new(book_id: book_id, chapter_id: chap_b).save
    expect(File).to exist(described_class.ledger_path(book_id, chap_a))
    expect(File).to exist(described_class.ledger_path(book_id, chap_b))
    expect(described_class.ledger_path(book_id, chap_a)).not_to eq(described_class.ledger_path(book_id, chap_b))
  end

  it "lists saved rows for a book" do
    described_class.new(book_id: book_id, chapter_id: chap_a, status: "fetched").save
    described_class.new(book_id: book_id, chapter_id: chap_b, status: "pending").save
    ids = described_class.list(book_id).map(&:chapter_id).sort
    expect(ids).to eq([chap_a, chap_b])
  end
end
