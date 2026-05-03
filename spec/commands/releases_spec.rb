# frozen_string_literal: true

RSpec.describe "releases and rollback" do
  let(:fake) { FakeApiClient.new }

  include_examples "passes APP through verbatim", command: "releases", path_pattern: "/apps/APP/releases", api_method: :get

  describe "releases" do
    it "GETs and tabulates" do
      fake.stub(:get, "/apps/5/releases", returns: [{ "version" => 3, "description" => "deploy", "created_at" => "2026-05-01T00:00:00Z" }])
      result = CliRunner.run("releases", "5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("v3")
    end
  end

  include_examples "respects --json",
    command: "releases",
    args: ["5"],
    path: "/apps/5/releases",
    fake_response: [{ "version" => 3, "description" => "deploy", "created_at" => "2026-05-01T00:00:00Z" }]

  describe "rollback" do
    it "POSTs /apps/:id/releases/:rid/rollback" do
      fake.stub(:post, "/apps/5/releases/3/rollback", returns: {})
      result = CliRunner.run("rollback", "5", "3", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Rolling back")
    end
  end
end
