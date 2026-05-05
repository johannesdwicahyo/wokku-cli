# frozen_string_literal: true

require "spec_helper"
require "support/fake_cable"
require "base64"

RSpec.describe "shell commands" do
  let(:fake) { FakeApiClient.new }
  let(:cable) {
    FakeCable.new(scripted_messages: [
      { "type" => "ready" },
      { "type" => "stdout", "data" => Base64.strict_encode64("hello\n") },
      { "type" => "exit",   "code" => 0 }
    ])
  }

  let(:console) { double("console", winsize: [24, 80], raw!: nil, cooked!: nil) }

  before do
    fake.stub(:get, "/apps/myapp", returns: { "id" => "uuid-app", "name" => "myapp", "server_id" => "uuid-srv" })
    allow(Wokku::CableClient).to receive(:new).and_return(cable)
    allow(cable).to receive(:subscribe)
    allow($stdout).to receive(:tty?).and_return(false)
    # Ensure a token is available so the "not logged in" guard doesn't fire:
    allow(Wokku::Config).to receive(:api_token).and_return("test-token")
    # Stub IO.console so PtySession raw!/cooked! calls don't hit the real terminal:
    allow(IO).to receive(:console).and_return(console)
    # Keep PtySession from touching real signal handlers:
    allow_any_instance_of(Wokku::PtySession).to receive(:install_signal_handlers)
  end

  describe "wokku enter" do
    it "subscribes with resolved server_id, sends start mode=enter, exits with remote code" do
      result = CliRunner.run("enter", "myapp", api: fake)
      expect(cable).to have_received(:subscribe).with(channel: "TerminalChannel", params: { server_id: "uuid-srv" })
      expect(cable.sent).to include(hash_including(type: "start", mode: "enter", target: "myapp"))
      expect(result.exit_code).to eq(0)
    end

    it "aborts when APP is missing" do
      result = CliRunner.run("enter", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr + result.stdout).to match(/Usage/i)
    end
  end

  describe "wokku ps:exec" do
    it "passes argv through and propagates non-zero exit code" do
      cable42 = FakeCable.new(scripted_messages: [
        { "type" => "ready" },
        { "type" => "exit",  "code" => 42 }
      ])
      allow(Wokku::CableClient).to receive(:new).and_return(cable42)
      allow(cable42).to receive(:subscribe)

      result = CliRunner.run("ps:exec", "myapp", "--", "rake", "db:migrate", api: fake)
      expect(cable42.sent).to include(
        hash_including(type: "start", mode: "exec", target: "myapp", argv: ["rake", "db:migrate"])
      )
      expect(result.exit_code).to eq(42)
    end

    it "parses -t (force TTY) without choking" do
      result = CliRunner.run("ps:exec", "-t", "myapp", "--", "top", api: fake)
      expect(result.exit_code).to eq(0)
    end

    it "parses -T (force no-TTY) without choking" do
      result = CliRunner.run("ps:exec", "-T", "myapp", "--", "ls", api: fake)
      expect(result.exit_code).to eq(0)
    end

    it "errors when -- and command are missing" do
      result = CliRunner.run("ps:exec", "myapp", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr + result.stdout).to match(/Usage/)
    end
  end

  describe "wokku databases:connect" do
    it "resolves db, sends start mode=db_connect" do
      fake.stub(:get, "/databases/mydb", returns: { "id" => "uuid-db", "name" => "mydb", "service_type" => "postgres", "server_id" => "uuid-srv" })
      result = CliRunner.run("databases:connect", "mydb", api: fake)
      expect(cable.sent).to include(hash_including(type: "start", mode: "db_connect", target: "mydb"))
      expect(result.exit_code).to eq(0)
    end

    it "aborts when DB is missing" do
      result = CliRunner.run("databases:connect", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr + result.stdout).to match(/Usage/i)
    end
  end

  describe "error path" do
    it "exits 1 when server emits an error message" do
      err_cable = FakeCable.new(scripted_messages: [{ "type" => "error", "message" => "access denied" }])
      allow(Wokku::CableClient).to receive(:new).and_return(err_cable)
      allow(err_cable).to receive(:subscribe)

      result = CliRunner.run("enter", "myapp", api: fake)
      expect(result.exit_code).to eq(1)
      expect(result.stderr).to include("access denied")
    end
  end

  describe "Wokku::Commands::Shell.derive_cable_url" do
    subject { Wokku::Commands::Shell }

    it "maps https:// to wss://" do
      expect(subject.derive_cable_url("https://wokku.cloud/api/v1")).to eq("wss://wokku.cloud/cable")
    end

    it "maps http:// to ws://" do
      expect(subject.derive_cable_url("http://localhost:3000/api/v1")).to eq("ws://localhost:3000/cable")
    end

    it "preserves non-standard port" do
      expect(subject.derive_cable_url("http://localhost:4567")).to eq("ws://localhost:4567/cable")
    end

    it "omits port 443 for wss://" do
      expect(subject.derive_cable_url("https://wokku.cloud:443/api/v1")).to eq("wss://wokku.cloud/cable")
    end
  end
end
