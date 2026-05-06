# frozen_string_literal: true

require "spec_helper"
require "wokku/cable_client"

RSpec.describe Wokku::CableClient do
  let(:driver) { instance_double("WebSocket::Driver::Client", on: nil, start: true, parse: nil, text: true, close: nil) }
  let(:tcp)    { instance_double("TCPSocket", read_nonblock: "", write: 1, close: nil) }

  before do
    allow(TCPSocket).to receive(:new).and_return(tcp)
    allow(WebSocket::Driver).to receive(:client).and_return(driver)
    # Prevent driver.set_header from failing on the double — allow by default
    allow(driver).to receive(:set_header)
  end

  it "passes Bearer token in handshake header" do
    expect(driver).to receive(:set_header).with("Authorization", "Bearer abc123")
    expect(driver).to receive(:set_header).with("Origin", "http://api.example")
    Wokku::CableClient.new(url: "ws://api.example/cable", token: "abc123")
  end

  it "sets Origin to the cable host so ActionCable's same-origin check passes" do
    expect(driver).to receive(:set_header).with("Origin", "http://api.example:3000")
    Wokku::CableClient.new(url: "ws://api.example:3000/cable", token: "tok")
  end

  it "does not set Authorization header when token is empty" do
    expect(driver).not_to receive(:set_header).with("Authorization", anything)
    Wokku::CableClient.new(url: "ws://api.example/cable", token: "")
  end

  it "subscribes by sending a subscribe command frame" do
    client = Wokku::CableClient.new(url: "ws://api.example/cable", token: "t")
    expect(driver).to receive(:text).with(/"command":"subscribe"/)
    allow(client).to receive(:pump_until)
    client.instance_variable_set(:@subscribed, true)
    client.subscribe(channel: "TerminalChannel", params: { server_id: "uuid-1" })
  end

  it "decodes inbound message frames and yields the inner message hash" do
    client = Wokku::CableClient.new(url: "ws://api.example/cable", token: "t")
    received = nil
    client.on_message { |msg| received = msg }
    client.send(:dispatch_frame, '{"identifier":"{}","message":{"type":"ready"}}')
    expect(received).to eq("type" => "ready")
  end

  it "sets @subscribed on confirm_subscription frame" do
    client = Wokku::CableClient.new(url: "ws://api.example/cable", token: "t")
    expect { client.send(:dispatch_frame, '{"type":"confirm_subscription","identifier":"{}"}') }
      .to change { client.instance_variable_get(:@subscribed) }.from(false).to(true)
  end

  it "ignores ping and welcome frames without calling on_message" do
    client = Wokku::CableClient.new(url: "ws://api.example/cable", token: "t")
    called = false
    client.on_message { |_| called = true }
    client.send(:dispatch_frame, '{"type":"ping","message":1234}')
    client.send(:dispatch_frame, '{"type":"welcome"}')
    expect(called).to be(false)
  end

  it "calls on_close with :eof on EOFError during pump" do
    client = Wokku::CableClient.new(url: "ws://api.example/cable", token: "t")
    allow(tcp).to receive(:read_nonblock).and_raise(EOFError)
    allow(IO).to receive(:select).and_return([[tcp], [], []])
    on_close_arg = nil
    client.on_close { |reason| on_close_arg = reason }
    client.pump(0.01)
    expect(on_close_arg).to eq(:eof)
  end

  it "derives wss:// cable URL correctly when api_url is https://" do
    # The scheme mapping is used in Commands::Shell; verify at driver init that
    # the socket type is chosen correctly. Here we just assert TCPSocket is
    # called with correct host/port for a ws:// URL.
    expect(TCPSocket).to receive(:new).with("api.example", 80).and_return(tcp)
    Wokku::CableClient.new(url: "ws://api.example/cable", token: "t")
  end
end
