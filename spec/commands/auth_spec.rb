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

  describe "auth:login" do
    it "POSTs /auth/login with the prompted credentials and saves the token" do
      stub_request(:post, "https://example.test/api/v1/auth/login")
        .with(body: { email: "a@b.com", password: "secret" }.to_json)
        .to_return(status: 200, body: { token: "tk_xyz" }.to_json)

      stdin = "https://example.test/api/v1\na@b.com\nsecret\n"
      result = CliRunner.run("auth:login", stdin: stdin)

      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Logged in as a@b.com")
      expect(Wokku::Config.load).to include("token" => "tk_xyz", "email" => "a@b.com")
    end
  end

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
