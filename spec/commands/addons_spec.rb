# frozen_string_literal: true

RSpec.describe "addons commands" do
  let(:fake) { FakeApiClient.new }

  include_examples "passes APP through verbatim", command: "addons", path_pattern: "/apps/APP/addons", api_method: :get

  describe "addons" do
    it "lists addons" do
      fake.stub(:get, "/apps/5/addons", returns: [{ "name" => "pg-1", "service_type" => "postgres", "status" => "ok" }])
      result = CliRunner.run("addons", "5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("pg-1")
    end
  end

  include_examples "respects --json",
    command: "addons",
    args: ["5"],
    path: "/apps/5/addons",
    fake_response: [{ "name" => "pg-1", "service_type" => "postgres", "status" => "ok" }]

  describe "addons:add" do
    it "POSTs with service_type" do
      fake.stub(:post, "/apps/5/addons", returns: { "name" => "pg-1" })
      result = CliRunner.run("addons:add", "5", "postgres", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(service_type: "postgres")
    end

    it "passes --name when given" do
      fake.stub(:post, "/apps/5/addons", returns: { "name" => "custom" })
      CliRunner.run("addons:add", "5", "postgres", "--name", "custom", api: fake)
      expect(fake.calls.first.body).to eq(service_type: "postgres", name: "custom")
    end
  end
end
