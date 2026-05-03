# frozen_string_literal: true

RSpec.describe "storage commands" do
  let(:fake) { FakeApiClient.new }

  include_examples "passes APP through verbatim", command: "storage", path_pattern: "/apps/APP/storage", api_method: :get

  describe "storage" do
    it "lists mounts" do
      fake.stub(:get, "/apps/5/storage", returns: { "mounts" => ["/host:/container"] })
      result = CliRunner.run("storage", "5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("/host:/container")
    end

    it "shows empty fallback" do
      fake.stub(:get, "/apps/5/storage", returns: [])
      result = CliRunner.run("storage", "5", api: fake)
      expect(result.stdout).to match(/no mounts/)
    end
  end

  describe "storage:mount" do
    it "POSTs mount spec" do
      fake.stub(:post, "/apps/5/storage", returns: {})
      result = CliRunner.run("storage:mount", "5", "/h:/c", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(mount: "/h:/c")
    end

    it "aborts when spec lacks colon" do
      result = CliRunner.run("storage:mount", "5", "bad", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "storage:unmount" do
    it "DELETEs with mount spec" do
      fake.stub(:delete, "/apps/5/storage", returns: {})
      result = CliRunner.run("storage:unmount", "5", "/h:/c", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(mount: "/h:/c")
    end
  end
end
