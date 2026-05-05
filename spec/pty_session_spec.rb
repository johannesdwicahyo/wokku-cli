# frozen_string_literal: true

require "spec_helper"
require "wokku/pty_session"

RSpec.describe Wokku::PtySession do
  let(:cable) { double("cable", send_message: nil, on_message: nil, pump: nil, close: nil) }
  let(:console) { double("console", winsize: [24, 80]) }

  before do
    allow(IO).to receive(:console).and_return(console)
    allow(console).to receive(:raw!)
    allow(console).to receive(:cooked!)
  end

  it "puts terminal in raw mode and restores on exit when tty: true" do
    expect(console).to receive(:raw!).ordered
    expect(console).to receive(:cooked!).ordered
    described_class.new(cable: cable, tty: true).run { :stop }
  end

  it "always restores cooked! even if block raises" do
    expect(console).to receive(:cooked!)
    expect {
      described_class.new(cable: cable, tty: true).run { raise "boom" }
    }.to raise_error("boom")
  end

  it "sends start payload with current cols/rows" do
    expect(cable).to receive(:send_message).with(hash_including(type: "start", cols: 80, rows: 24))
    described_class.new(cable: cable, tty: true).start!(mode: "enter", target: "myapp", argv: [])
  end

  it "skips raw mode when tty: false (no-TTY ps:exec)" do
    expect(console).not_to receive(:raw!)
    expect(console).not_to receive(:cooked!)
    described_class.new(cable: cable, tty: false).run { :stop }
  end

  it "sets exit_code from exit message" do
    # Use a cable double that replays an exit message on pump
    msg_cable = double("cable", send_message: nil, close: nil)
    received_handler = nil
    allow(msg_cable).to receive(:on_message) { |&blk| received_handler = blk }
    allow(msg_cable).to receive(:pump) { received_handler&.call("type" => "exit", "code" => 42) }

    session = described_class.new(cable: msg_cable, tty: false)
    session.run
    expect(session.exit_code).to eq(42)
  end

  it "sets exit_code 1 and marks done on error message" do
    msg_cable = double("cable", send_message: nil, close: nil)
    received_handler = nil
    allow(msg_cable).to receive(:on_message) { |&blk| received_handler = blk }
    allow(msg_cable).to receive(:pump) { received_handler&.call("type" => "error", "message" => "access denied") }

    session = described_class.new(cable: msg_cable, tty: false)
    session.run
    expect(session.exit_code).to eq(1)
  end
end
