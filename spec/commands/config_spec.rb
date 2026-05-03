# frozen_string_literal: true

RSpec.describe "config commands" do
  let(:fake) { FakeApiClient.new }

  include_examples "passes APP through verbatim", command: "config", path_pattern: "/apps/APP/config", api_method: :get

  describe "config" do
    it "lists vars as KEY=VALUE" do
      fake.stub(:get, "/apps/5/config", returns: { "FOO" => "bar", "BAZ" => "qux" })
      result = CliRunner.run("config", "5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("FOO=bar").and include("BAZ=qux")
    end
  end

  describe "config:set" do
    it "PUTs /apps/:id/config with vars wrapper" do
      fake.stub(:put, "/apps/5/config", returns: {})
      result = CliRunner.run("config:set", "5", "FOO=bar", "BAZ=qux", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("FOO").and include("BAZ")
      expect(fake.calls.first.body).to eq(vars: { "FOO" => "bar", "BAZ" => "qux" })
    end

    it "aborts when no KEY=VALUE pairs" do
      result = CliRunner.run("config:set", "5", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "config:get" do
    it "prints the value when set" do
      fake.stub(:get, "/apps/5/config", returns: { "FOO" => "bar" })
      result = CliRunner.run("config:get", "5", "FOO", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout.strip).to eq("bar")
    end

    it "aborts when key not set" do
      fake.stub(:get, "/apps/5/config", returns: { "FOO" => "bar" })
      result = CliRunner.run("config:get", "5", "MISSING", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr + result.stdout).to match(/Key not set/i)
    end
  end

  include_examples "respects --json",
    command: "config",
    args: ["5"],
    path: "/apps/5/config",
    fake_response: { "FOO" => "bar" }

  include_examples "respects --quiet",
    command: "config:set",
    args: ["5", "FOO=bar"],
    path: "/apps/5/config",
    api_method: :put,
    fake_response: {}

  describe "config:unset" do
    it "DELETEs /apps/:id/config with keys list" do
      fake.stub(:delete, "/apps/5/config", returns: {})
      result = CliRunner.run("config:unset", "5", "FOO", "BAZ", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Removed: FOO, BAZ")
      expect(fake.calls.first.body).to eq(keys: %w[FOO BAZ])
    end
  end
end
