# frozen_string_literal: true

RSpec.describe "process commands" do
  let(:fake) { FakeApiClient.new }

  include_examples "passes APP through verbatim", command: "ps:restart", path_pattern: "/apps/APP/restart", api_method: :post

  shared_examples "simple POST action" do |command, path, output_match|
    it "POSTs #{path} and prints expected output" do
      fake.stub(:post, path, returns: {})
      result = CliRunner.run(command, "5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(output_match)
      expect(fake.calls.first).to have_attributes(method: :post, path: path)
    end
  end

  it_behaves_like "simple POST action", "ps:restart", "/apps/5/restart", /Restarting/
  it_behaves_like "simple POST action", "ps:stop",    "/apps/5/stop",    /Stopped/
  it_behaves_like "simple POST action", "ps:start",   "/apps/5/start",   /Started/

  describe "ps:rebuild" do
    it "POSTs /apps/:id/deploy and reports deploy/release ids" do
      fake.stub(:post, "/apps/5/deploy", returns: { "deploy_id" => 11, "release_id" => 22 })
      result = CliRunner.run("ps:rebuild", "5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Deploy #11").and include("release #22")
    end
  end

  describe "redeploy" do
    it "POSTs /apps/:id/deploy and reports ids" do
      fake.stub(:post, "/apps/5/deploy", returns: { "deploy_id" => 33, "release_id" => 44 })
      result = CliRunner.run("redeploy", "5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Deploy #33").and include("release #44")
    end
  end

  describe "ps:scale" do
    it "PATCHes /apps/:id/ps with parsed scaling pairs" do
      fake.stub(:patch, "/apps/5/ps", returns: {})
      result = CliRunner.run("ps:scale", "5", "web=2", "worker=1", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("web=2").and include("worker=1")
      expect(fake.calls.first.body).to eq(scaling: { "web" => 2, "worker" => 1 })
    end

    it "aborts when no scaling pairs given" do
      result = CliRunner.run("ps:scale", "5", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr + result.stdout).to match(/scaling pairs/i)
    end
  end
end
