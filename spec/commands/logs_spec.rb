# frozen_string_literal: true

RSpec.describe "logs command" do
  let(:fake) { FakeApiClient.new }

  include_examples "passes APP through verbatim", command: "logs", path_pattern: "/apps/APP/logs?lines=100", api_method: :get

  it "GETs /apps/:id/logs and prints array entries" do
    fake.stub(:get, "/apps/5/logs?lines=100", returns: ["line1", "line2"])
    result = CliRunner.run("logs", "5", api: fake)
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to include("line1").and include("line2")
  end

  it "honors --lines" do
    fake.stub(:get, "/apps/5/logs?lines=500", returns: [])
    result = CliRunner.run("logs", "5", "--lines", "500", api: fake)
    expect(result.exit_code).to eq(0)
    expect(fake.calls.first.path).to eq("/apps/5/logs?lines=500")
  end

  include_examples "respects --json",
    command: "logs",
    args: ["5"],
    path: "/apps/5/logs?lines=100",
    fake_response: ["line1", "line2"]

  describe "--follow" do
    it "streams chunks via ApiClient#stream" do
      fake = FakeApiClient.new
      fake.stub(:get, "/apps/5/logs?follow=1", returns: ["chunk1\n", "chunk2\n"])
      result = CliRunner.run("logs", "5", "--follow", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to eq("chunk1\nchunk2\n")
    end

    it "accepts -f as a short form" do
      fake = FakeApiClient.new
      fake.stub(:get, "/apps/5/logs?follow=1", returns: ["x\n"])
      result = CliRunner.run("logs", "5", "-f", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("x")
    end
  end
end
