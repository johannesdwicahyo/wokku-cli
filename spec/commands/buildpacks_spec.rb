# frozen_string_literal: true

RSpec.describe "buildpacks commands" do
  let(:fake) { FakeApiClient.new }

  include_examples "passes APP through verbatim", command: "buildpacks", path_pattern: "/apps/APP/buildpacks", api_method: :get

  describe "buildpacks" do
    it "lists numbered URLs" do
      fake.stub(:get, "/apps/5/buildpacks", returns: { "buildpacks" => ["a", "b"] })
      result = CliRunner.run("buildpacks", "5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("1. a").and include("2. b")
    end

    it "shows fallback message when empty" do
      fake.stub(:get, "/apps/5/buildpacks", returns: [])
      result = CliRunner.run("buildpacks", "5", api: fake)
      expect(result.stdout).to match(/auto-detected/)
    end
  end

  describe "buildpacks:add" do
    it "POSTs URL" do
      fake.stub(:post, "/apps/5/buildpacks", returns: {})
      result = CliRunner.run("buildpacks:add", "5", "https://x", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Added buildpack: https://x")
      expect(fake.calls.first.body).to eq(url: "https://x")
    end

    it "passes --index when provided" do
      fake.stub(:post, "/apps/5/buildpacks", returns: {})
      CliRunner.run("buildpacks:add", "5", "https://x", "--index", "2", api: fake)
      expect(fake.calls.first.body).to eq(url: "https://x", index: "2")
    end
  end

  describe "buildpacks:remove" do
    it "DELETEs with URL body" do
      fake.stub(:delete, "/apps/5/buildpacks", returns: {})
      result = CliRunner.run("buildpacks:remove", "5", "https://x", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(url: "https://x")
    end
  end

  describe "buildpacks:clear" do
    it "DELETEs without body" do
      fake.stub(:delete, "/apps/5/buildpacks", returns: {})
      result = CliRunner.run("buildpacks:clear", "5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("All buildpacks removed")
      expect(fake.calls.first.body).to be_nil
    end
  end

  describe "buildpacks:set" do
    it "PUTs the urls array in order" do
      fake.stub(:put, "/apps/5/buildpacks", returns: {})
      result = CliRunner.run("buildpacks:set", "5", "https://a", "https://b", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(urls: ["https://a", "https://b"])
    end
  end
end
