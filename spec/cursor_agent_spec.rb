require "open3"

RSpec.describe NovelTrans::CursorAgent do
  def status(success)
    instance_double(Process::Status, success?: success)
  end

  it "runs cursor agent in print ask mode without --yolo" do
    expect(Open3).to receive(:capture3) do |*argv|
      expect(argv[0]).to eq("cursor")
      expect(argv).to include("agent", "-p", "--mode", "ask", "--trust")
      expect(argv).to include("--model", "gemini-3.7-flash-high")
      expect(argv).to include("--workspace", NovelTrans.root)
      expect(argv).not_to include("--yolo", "--force")
      expect(argv.last).to include("第一章")
      ["Chương 1", "", status(true)]
    end

    vi = described_class.new(model: described_class::MODEL).translate("第一章\n\n城门外")
    expect(vi).to eq("Chương 1")
  end

  it "raises when cursor agent exits non-zero" do
    allow(Open3).to receive(:capture3).and_return(["", "boom", status(false)])
    expect { described_class.new.translate("第一章") }.to raise_error(NovelTrans::Error, /boom/)
  end

  it "raises when cursor agent prints nothing" do
    allow(Open3).to receive(:capture3).and_return(["  \n", "", status(true)])
    expect { described_class.new.translate("第一章") }.to raise_error(NovelTrans::Error, /no Vietnamese/)
  end

  it "raises when cursor is not on PATH" do
    allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)
    expect { described_class.new.translate("第一章") }.to raise_error(NovelTrans::Error, /cursor not found/)
  end
end
