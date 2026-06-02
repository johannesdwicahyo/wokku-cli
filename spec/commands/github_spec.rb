# frozen_string_literal: true

RSpec.describe "github commands" do
  let(:fake) { FakeApiClient.new }

  describe "github:connect" do
    it "POSTs to /apps/APP/github_connect with repo + default branch" do
      fake.stub(:post, "/apps/myapp/github_connect", returns: { "message" => "Connected to me/repo (main)" })
      result = CliRunner.run("github:connect", "myapp", "me/repo", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(repo: "me/repo", branch: "main")
      expect(result.stdout).to match(/Connected/)
    end

    it "respects --branch flag" do
      fake.stub(:post, "/apps/myapp/github_connect", returns: { "message" => "ok" })
      CliRunner.run("github:connect", "myapp", "me/repo", "--branch", "dev", api: fake)
      expect(fake.calls.first.body).to eq(repo: "me/repo", branch: "dev")
    end

    it "aborts when REPO is missing" do
      result = CliRunner.run("github:connect", "myapp", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "github:disconnect" do
    it "DELETEs /apps/APP/github_disconnect" do
      fake.stub(:delete, "/apps/myapp/github_disconnect", returns: { "message" => "Disconnected" })
      result = CliRunner.run("github:disconnect", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/Disconnected/)
    end

    it "aborts when APP is missing" do
      result = CliRunner.run("github:disconnect", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end
end
