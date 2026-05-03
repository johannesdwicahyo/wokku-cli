# frozen_string_literal: true

RSpec.describe Wokku::Output do
  describe ".render" do
    it "yields data when --json is not set" do
      Wokku.json = false
      yielded = nil
      described_class.render({ "x" => 1 }) { |d| yielded = d }
      expect(yielded).to eq({ "x" => 1 })
    end

    it "prints data as pretty JSON when --json is set" do
      Wokku.json = true
      out = capture_stdout { described_class.render({ "x" => 1 }) { fail "block must not run when --json" } }
      expect(JSON.parse(out)).to eq({ "x" => 1 })
    end
  end

  describe ".status" do
    it "puts the message normally" do
      Wokku.json = false
      Wokku.quiet = false
      out = capture_stdout { described_class.status("hello") }
      expect(out).to eq("hello\n")
    end

    it "suppresses the message when --quiet" do
      Wokku.quiet = true
      out = capture_stdout { described_class.status("hello") }
      expect(out).to eq("")
    end

    it "suppresses the message when --json" do
      Wokku.json = true
      out = capture_stdout { described_class.status("hello") }
      expect(out).to eq("")
    end
  end

  def capture_stdout
    old, $stdout = $stdout, StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old
  end
end
