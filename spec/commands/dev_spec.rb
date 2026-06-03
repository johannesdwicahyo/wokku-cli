# frozen_string_literal: true

RSpec.describe "dev command" do
  let(:fake) { FakeApiClient.new }
  let(:session_payload) do
    {
      "session_id" => "sid",
      "ssh_host"   => "103.190.0.43",
      "ssh_port"   => 22,
      "ssh_user"   => "dev",
      "db_remote_host" => "172.17.0.6",
      "db_remote_port" => 5432,
      "local_port_suggestion" => 5433,
      "readonly"   => true,
      "expires_at" => (Time.now + 1800).iso8601
    }
  end

  before do
    fake.stub(:post, "/apps/myapp/dev_sessions", returns: session_payload)
    fake.stub(:get,  "/apps/myapp/config", returns: { "DATABASE_URL" => "postgres://wokku:secret@host:5432/db" })
    fake.stub(:delete, "/apps/myapp/dev_sessions/sid", returns: nil)
    allow(Process).to receive(:spawn).and_return(99999) # tunnel pid
    allow(Process).to receive(:wait2).and_return([99999, instance_double(Process::Status, exitstatus: 0)])
    allow(Process).to receive(:kill)
    allow_any_instance_of(Object).to receive(:sleep)
    # Stub tunnel readiness check — Socket.tcp yields a socket on success
    allow(Socket).to receive(:tcp).and_yield(StringIO.new)
  end

  it "POSTs to create a session, opens an SSH tunnel, then spawns the user command" do
    result = CliRunner.run("dev", "myapp", "--", "echo", "hello", api: fake)
    expect(result.exit_code).to eq(0)
    create_call = fake.calls.find { |c| c.path == "/apps/myapp/dev_sessions" && c.method == :post }
    expect(create_call.body).to include(duration_min: 30)
  end

  it "respects --duration" do
    CliRunner.run("dev", "myapp", "--duration", "45", "--", "echo", "hi", api: fake)
    create_call = fake.calls.find { |c| c.path == "/apps/myapp/dev_sessions" && c.method == :post }
    expect(create_call.body).to include(duration_min: 45)
  end

  it "aborts when APP missing" do
    result = CliRunner.run("dev", "--", "echo", "hi", api: fake)
    expect(result.exit_code).not_to eq(0)
  end

  it "aborts when user command missing (no -- separator)" do
    result = CliRunner.run("dev", "myapp", api: fake)
    expect(result.exit_code).not_to eq(0)
  end

  it "revokes the session via DELETE on user-command exit" do
    CliRunner.run("dev", "myapp", "--", "echo", "hi", api: fake)
    delete_call = fake.calls.find { |c| c.path == "/apps/myapp/dev_sessions/sid" && c.method == :delete }
    expect(delete_call).to be_truthy
  end

  describe "DATABASE_URL rewriting" do
    it "rewrites host:port to localhost:LOCAL_PORT and adds read_only by default" do
      captured = nil
      allow(Process).to receive(:spawn) do |env, *cmd, **opts|
        captured = env if env.is_a?(Hash)
        99999
      end
      CliRunner.run("dev", "myapp", "--", "echo", "hi", api: fake)
      expect(captured["DATABASE_URL"]).to match(%r{@localhost:5433/})
      expect(captured["DATABASE_URL"]).to include("default_transaction_read_only")
    end

    it "skips read_only and prints banner with --rw" do
      captured = nil
      allow(Process).to receive(:spawn) do |env, *cmd, **opts|
        captured = env if env.is_a?(Hash)
        99999
      end
      result = CliRunner.run("dev", "myapp", "--rw", "--", "echo", "hi", api: fake)
      expect(captured["DATABASE_URL"]).to match(%r{@localhost:5433/})
      expect(captured["DATABASE_URL"]).not_to include("default_transaction_read_only")
      combined = "#{result.stdout}#{result.stderr}"
      expect(combined).to match(/--rw MODE|PROD database/i)
    end
  end
end
