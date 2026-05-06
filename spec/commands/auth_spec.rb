# frozen_string_literal: true

RSpec.describe "auth commands" do
  let(:fake) { FakeApiClient.new }

  describe "auth:whoami" do
    it "calls GET /auth/whoami and prints email + role" do
      fake.stub(:get, "/auth/whoami", returns: { "email" => "a@b.com", "role" => "admin" })
      result = CliRunner.run("auth:whoami", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("a@b.com").and include("admin")
      expect(fake.calls.first.method).to eq(:get)
      expect(fake.calls.first.path).to eq("/auth/whoami")
    end
  end

  describe "auth:login (device flow)" do
    it "starts a device-code session, polls until approval, saves the token" do
      stub_request(:post, "https://example.test/api/v1/auth/device/code")
        .to_return(status: 200, body: {
          device_code: "dev_abc",
          user_code: "AAAA-BBBB",
          verification_uri_complete: "https://example.test/dashboard/device?user_code=AAAA-BBBB",
          interval: 0,
          expires_in: 600
        }.to_json)

      stub_request(:post, "https://example.test/api/v1/auth/device/token")
        .with(body: { device_code: "dev_abc" }.to_json)
        .to_return(
          { status: 202, body: { error: "authorization_pending" }.to_json },
          { status: 200, body: { token: "tk_xyz", user: { email: "a@b.com" } }.to_json }
        )

      allow(Wokku::Auth).to receive(:open_browser)  # don't actually launch a browser
      allow(Wokku::Auth).to receive(:sleep_for)     # speed up the poll loop in tests

      result = CliRunner.run("auth:login", "--url", "https://example.test/api/v1")

      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("AAAA-BBBB").and include("Logged in as a@b.com")
      expect(Wokku::Config.load).to include("token" => "tk_xyz", "email" => "a@b.com")
    end

    it "supports legacy email+password flow with --password" do
      stub_request(:post, "https://example.test/api/v1/auth/login")
        .with(body: { email: "a@b.com", password: "secret" }.to_json)
        .to_return(status: 200, body: { token: "tk_xyz" }.to_json)

      stdin = "a@b.com\nsecret\n"
      result = CliRunner.run("auth:login", "--url", "https://example.test/api/v1", "--password", stdin: stdin)

      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Logged in as a@b.com")
      expect(Wokku::Config.load).to include("token" => "tk_xyz", "email" => "a@b.com")
    end
  end

  include_examples "respects --json",
    command: "auth:whoami",
    path: "/auth/whoami",
    fake_response: { "email" => "a@b.com", "role" => "admin" }

  describe "auth:logout" do
    it "deletes the config file when present" do
      Wokku::Config.save("token" => "tk_xyz", "email" => "a@b.com")
      result = CliRunner.run("auth:logout")
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Logged out")
      expect(File.exist?(Wokku::Config.file)).to be(false)
    end

    it "is a no-op when not logged in" do
      File.delete(Wokku::Config.file) if File.exist?(Wokku::Config.file)
      result = CliRunner.run("auth:logout")
      expect(result.stdout).to include("Not logged in")
    end
  end
end
