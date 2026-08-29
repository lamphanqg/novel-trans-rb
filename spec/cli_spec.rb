RSpec.describe NovelTrans::CLI do
  let(:book_id) { "1036645930" }

  def invoke_status(**opts)
    described_class.new.invoke(:status, [], { book: book_id }.merge(opts))
  end

  it "prints a count row for every status" do
    NovelTrans::ChapterWork.new(book_id:, chapter_id: "747314648", status: "fetched").save
    NovelTrans::ChapterWork.new(book_id:, chapter_id: "747314649", status: "fetched").save
    NovelTrans::ChapterWork.new(book_id:, chapter_id: "747314650", status: "failed").save

    expect { invoke_status }.to output(
      <<~TSV
        status	count
        pending	0
        locked	0
        fetched	2
        translated	0
        uploaded	0
        failed	1
        total	3
      TSV
    ).to_stdout
  end

  it "prints matching rows when --status is set" do
    NovelTrans::ChapterWork.new(book_id:, chapter_id: "747314648", status: "fetched").save
    NovelTrans::ChapterWork.new(book_id:, chapter_id: "747314649", status: "failed").save

    expect { invoke_status(status: "failed") }.to output(
      <<~TSV
        book_id	chapter_id	status
        #{book_id}	747314649	failed
      TSV
    ).to_stdout
  end

  it "rejects an unknown --status" do
    expect { invoke_status(status: "done") }.to raise_error(ArgumentError, /unknown status/)
  end

  it "names --html-file in fetch help" do
    expect { described_class.start(%w[help fetch]) }.to output(/html-file/).to_stdout
  end

  it "does not take a --cdp flag" do
    expect { described_class.start(%w[help fetch]) }.not_to output(/cdp/).to_stdout
  end

  it "tells the operator to start qidian-chrome when Chrome is not listening" do
    allow(NovelTrans::Qidian::Session).to receive(:connect)
      .and_raise(NovelTrans::Error, "live fetch needs bin/qidian-chrome")
    expect do
      described_class.new.invoke(
        :fetch,
        [],
        { book: book_id, url: ["https://www.qidian.com/chapter/#{book_id}/747314648/"] }
      )
    end.to raise_error(NovelTrans::Error, /qidian-chrome/)
  end
end
