# frozen_string_literal: true

RSpec.describe "previews commands" do
  let(:fake) { FakeApiClient.new }

  describe "previews" do
    it "GETs /apps/APP/previews and prints" do
      fake.stub(:get, "/apps/myapp/previews", returns: [
        { "id" => "p1", "name" => "pr-42-myapp", "pr_number" => 42, "branch" => "feat/foo", "status" => "running", "url" => "https://pr-42-myapp.wokku.app" }
      ])
      result = CliRunner.run("previews", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/#42/)
      expect(result.stdout).to match(/feat\/foo/)
    end

    it "prints a friendly message when empty" do
      fake.stub(:get, "/apps/myapp/previews", returns: [])
      result = CliRunner.run("previews", "myapp", api: fake)
      expect(result.stdout).to match(/no preview/i)
    end
  end

  describe "previews:destroy" do
    it "DELETEs /apps/APP/previews/PR_NUMBER" do
      fake.stub(:delete, "/apps/myapp/previews/42", returns: { "message" => "Preview destroy queued" })
      result = CliRunner.run("previews:destroy", "myapp", "42", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/queued/i)
    end

    it "aborts when PR_NUMBER missing" do
      result = CliRunner.run("previews:destroy", "myapp", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end
end
