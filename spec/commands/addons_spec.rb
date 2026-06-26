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

  describe "addons:shared:enable (poll-until-running)" do
    it "reports success once the engine shows running" do
      fake.stub(:post, "/apps/myapp/addons/shared",
                returns: { "message" => "Shared redis enabled and provisioning queued." })
      fake.stub_sequence(:get, "/apps/myapp/addons", [
        [{ "service_type" => "redis", "shared" => true, "status" => "creating" }],
        [{ "service_type" => "redis", "shared" => true, "status" => "running" }]
      ])

      result = CliRunner.run("addons:shared:enable", "myapp", "redis", api: fake,
                             env: { "WOKKU_POLL_INTERVAL" => "0" })
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/ready/i)
    end

    it "reports failure when the engine shows error" do
      fake.stub(:post, "/apps/myapp/addons/shared", returns: { "message" => "queued" })
      fake.stub(:get, "/apps/myapp/addons",
                returns: [{ "service_type" => "redis", "shared" => true, "status" => "error" }])

      result = CliRunner.run("addons:shared:enable", "myapp", "redis", api: fake,
                             env: { "WOKKU_POLL_INTERVAL" => "0" })
      expect(result.exit_code).not_to eq(0)
      # abort writes to stderr (standard CLI error convention).
      expect(result.stderr).to match(/failed/i)
    end

    it "reports still-provisioning on timeout" do
      fake.stub(:post, "/apps/myapp/addons/shared", returns: { "message" => "queued" })
      fake.stub(:get, "/apps/myapp/addons",
                returns: [{ "service_type" => "redis", "shared" => true, "status" => "creating" }])

      result = CliRunner.run("addons:shared:enable", "myapp", "redis", api: fake,
                             env: { "WOKKU_POLL_INTERVAL" => "0", "WOKKU_POLL_ATTEMPTS" => "2" })
      expect(result.stdout).to match(/still provisioning/i)
    end
  end
end
