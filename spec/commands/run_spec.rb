# frozen_string_literal: true

RSpec.describe "run commands" do
  let(:fake) { FakeApiClient.new }

  describe "run" do
    it "starts the run, polls to completion, prints output and exits with its code" do
      fake.stub(:post, "/apps/a/run", returns: { "run_id" => "r1" })
      fake.stub(:get, "/apps/a/runs/r1", returns: { "run_id" => "r1", "status" => "failed", "exit_code" => 3, "output" => "boom" })
      result = CliRunner.run("run", "a", "--", "rake", "x", api: fake)
      expect(fake.calls.first.body).to eq(command: "rake x")
      expect(result.stdout).to include("boom")
      expect(result.exit_code).to eq(3)
    end

    it "exits 0 on success" do
      fake.stub(:post, "/apps/a/run", returns: { "run_id" => "r1" })
      fake.stub(:get, "/apps/a/runs/r1", returns: { "status" => "succeeded", "exit_code" => 0, "output" => "ok" })
      expect(CliRunner.run("run", "a", "--", "true", api: fake).exit_code).to eq(0)
    end

    it "aborts without a command" do
      expect(CliRunner.run("run", "a", api: fake).exit_code).not_to eq(0)
    end
  end

  describe "run:status" do
    it "GETs the run" do
      fake.stub(:get, "/apps/a/runs/r1", returns: { "status" => "pending" })
      result = CliRunner.run("run:status", "a", "r1", api: fake)
      expect(result.stdout).to include("pending")
    end
  end
end
