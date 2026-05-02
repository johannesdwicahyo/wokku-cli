# frozen_string_literal: true

RSpec.describe "releases and rollback" do
  let(:fake) { FakeApiClient.new }

  describe "releases" do
    it "GETs and tabulates" do
      fake.stub(:get, "/apps/5/releases", returns: [{ "version" => 3, "description" => "deploy", "created_at" => "2026-05-01T00:00:00Z" }])
      result = CliRunner.run("releases", "5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("v3")
    end
  end

  describe "rollback" do
    it "POSTs /apps/:id/releases/:rid/rollback" do
      fake.stub(:post, "/apps/5/releases/3/rollback", returns: {})
      result = CliRunner.run("rollback", "5", "3", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Rolling back")
    end
  end
end
