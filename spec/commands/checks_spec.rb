# frozen_string_literal: true

RSpec.describe "checks commands" do
  let(:fake) { FakeApiClient.new }

  include_examples "passes APP through verbatim", command: "checks", path_pattern: "/apps/APP/checks", api_method: :get

  describe "checks" do
    it "GETs and prints JSON" do
      fake.stub(:get, "/apps/5/checks", returns: { "enabled" => true, "path" => "/healthz" })
      result = CliRunner.run("checks", "5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("\"path\": \"/healthz\"")
    end
  end

  describe "checks:set" do
    it "PUTs only the flags provided" do
      fake.stub(:put, "/apps/5/checks", returns: {})
      result = CliRunner.run("checks:set", "5", "--enabled", "true", "--path", "/healthz", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(enabled: "true", path: "/healthz")
    end

    it "aborts when no flags given" do
      result = CliRunner.run("checks:set", "5", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end
end
