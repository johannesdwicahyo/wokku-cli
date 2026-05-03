# frozen_string_literal: true

# Snapshot/restore the COMMANDS hash so this spec doesn't blow away the
# entries every command file populates at load time. Plain `.clear` in
# before/after would orphan all 43 commands for every other spec in the run.
RSpec.describe Wokku::Registry do
  around do |ex|
    snapshot = described_class::COMMANDS.dup
    described_class::COMMANDS.clear
    begin
      ex.run
    ensure
      described_class::COMMANDS.clear
      described_class::COMMANDS.merge!(snapshot)
    end
  end

  it "register populates COMMANDS with desc + handler" do
    described_class.register("foo", "the foo command") { :ran }
    entry = described_class::COMMANDS["foo"]
    expect(entry[:desc]).to eq("the foo command")
    expect(entry[:handler].call).to eq(:ran)
  end

  it "registering the same name overwrites the prior entry" do
    described_class.register("dup", "first") { :a }
    described_class.register("dup", "second") { :b }
    expect(described_class::COMMANDS["dup"][:desc]).to eq("second")
    expect(described_class::COMMANDS["dup"][:handler].call).to eq(:b)
  end
end
