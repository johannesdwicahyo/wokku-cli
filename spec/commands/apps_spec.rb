# frozen_string_literal: true

RSpec.describe "apps commands" do
  let(:fake) { FakeApiClient.new }

  describe "apps" do
    it "lists apps via GET /apps" do
      fake.stub(:get, "/apps", returns: [
        { "name" => "alpha", "status" => "running", "server_id" => 1 },
        { "name" => "beta",  "status" => "stopped", "server_id" => 2 }
      ])
      result = CliRunner.run("apps", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("alpha").and include("beta")
    end
  end

  describe "apps:info" do
    it "GETs /apps/:id and prints JSON" do
      fake.stub(:get, "/apps/42", returns: { "id" => 42, "name" => "alpha" })
      result = CliRunner.run("apps:info", "42", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("\"name\": \"alpha\"")
    end

    it "aborts when APP_ID is missing" do
      result = CliRunner.run("apps:info", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr + result.stdout).to match(/Usage:/i)
    end
  end

  describe "apps:create" do
    it "POSTs /apps with name and server_id" do
      fake.stub(:post, "/apps", returns: { "id" => 9, "name" => "gamma" })
      result = CliRunner.run("apps:create", "gamma", "--server", "1", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Created app: gamma")
      call = fake.calls.find { |c| c.method == :post && c.path == "/apps" }
      expect(call.body).to include(name: "gamma", server_id: 1, deploy_branch: "main")
    end

    it "aborts when --server is missing" do
      result = CliRunner.run("apps:create", "gamma", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr + result.stdout).to match(/--server/)
    end
  end

  describe "apps:info name/UUID interchangeability" do
    include_examples "passes APP through verbatim", command: "apps:info", path_pattern: "/apps/APP", api_method: :get
  end

  describe "apps:destroy" do
    it "DELETEs /apps/:id when confirmed with y" do
      fake.stub(:delete, "/apps/7", returns: { "ok" => true })
      result = CliRunner.run("apps:destroy", "7", api: fake, stdin: "y\n")
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("App deleted")
      expect(fake.calls.last.method).to eq(:delete)
    end

    it "cancels when confirmation is not 'y'" do
      result = CliRunner.run("apps:destroy", "7", api: fake, stdin: "n\n")
      expect(result.exit_code).not_to eq(0)
      expect(fake.calls).to be_empty
    end
  end
end
