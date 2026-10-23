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

  include_examples "respects --quiet",
    command: "ps:restart",
    args: ["5"],
    path: "/apps/5/restart",
    api_method: :post,
    fake_response: {}

  describe "ps" do
    it "GETs the process formation" do
      fake.stub(:get, "/apps/a/ps", returns: { "processes" => { "status_web_1" => "running" } })
      result = CliRunner.run("ps", "a", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("status_web_1: running")
    end
  end

  describe "ps:sizes" do
    it "lists box sizes" do
      fake.stub(:get, "/dyno_tiers", returns: [ { "name" => "standard", "memory_mb" => 1024 } ])
      expect(CliRunner.run("ps:sizes", api: fake).stdout).to include("standard")
    end
  end

  describe "ps:dynos" do
    it "lists allocations" do
      fake.stub(:get, "/apps/a/dynos", returns: [ { "id" => "y1", "process_type" => "web", "count" => 1, "size_label" => "Starter", "monthly_cost_cents" => 2400 } ])
      expect(CliRunner.run("ps:dynos", "a", api: fake).stdout).to include("Starter")
    end
  end

  describe "ps:resize" do
    it "PATCHes the resources shape for the process type" do
      fake.stub(:patch, "/apps/a/ps", returns: { "message" => "Resources updated" })
      result = CliRunner.run("ps:resize", "a", "worker", "--memory", "1024", "--cpu", "0.5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.last.body).to eq(resources: { "worker" => { memory_mb: 1024, cpu: 0.5 } })
    end

    it "accepts flags before nothing else in any order" do
      fake.stub(:patch, "/apps/a/ps", returns: {})
      result = CliRunner.run("ps:resize", "a", "web", "--cpu", "1", "--memory", "512", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.last.body).to eq(resources: { "web" => { cpu: 1.0, memory_mb: 512 } })
    end

    it "aborts with neither --memory nor --cpu" do
      expect(CliRunner.run("ps:resize", "a", "web", api: fake).exit_code).not_to eq(0)
      expect(fake.calls).to be_empty
    end

    it "aborts without TYPE" do
      expect(CliRunner.run("ps:resize", "a", api: fake).exit_code).not_to eq(0)
      expect(fake.calls).to be_empty
    end
  end
end
