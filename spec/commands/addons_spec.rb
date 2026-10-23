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

  describe "addons:remove" do
    it "asks, then DELETEs the add-on" do
      fake.stub(:delete, "/apps/a/addons/x1", returns: {})
      result = CliRunner.run("addons:remove", "a", "x1", api: fake, stdin: "y\n")
      expect(result.exit_code).to eq(0)
      expect(fake.calls.last.method).to eq(:delete)
    end
  end

  describe "addons:remove (cancel)" do
    it "aborts without calling the API on anything but y" do
      result = CliRunner.run("addons:remove", "a", "x1", api: fake, stdin: "n\n")
      expect(result.exit_code).not_to eq(0)
      expect(fake.calls).to be_empty
    end
  end

  describe "addons:add" do
    it "is retired and points at the replacements without calling the API" do
      result = CliRunner.run("addons:add", "a", "postgres", api: fake)
      expect(result.stderr + result.stdout).to include("addons:shared:enable")
      expect(fake.calls).to be_empty
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
