# frozen_string_literal: true

RSpec.describe "domains commands" do
  let(:fake) { FakeApiClient.new }

  describe "domains" do
    it "lists hostnames" do
      fake.stub(:get, "/apps/5/domains", returns: [{ "id" => 1, "hostname" => "a.com" }, { "id" => 2, "hostname" => "b.com" }])
      result = CliRunner.run("domains", "5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("a.com").and include("b.com")
    end
  end

  describe "domains:add" do
    it "POSTs the hostname" do
      fake.stub(:post, "/apps/5/domains", returns: { "id" => 9, "hostname" => "x.com" })
      result = CliRunner.run("domains:add", "5", "x.com", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Added domain: x.com")
      expect(fake.calls.first.body).to eq(hostname: "x.com")
    end
  end

  describe "domains:remove" do
    it "looks up the row and DELETEs by id" do
      fake.stub(:get, "/apps/5/domains", returns: [{ "id" => 9, "hostname" => "x.com" }])
      fake.stub(:delete, "/apps/5/domains/9", returns: {})
      result = CliRunner.run("domains:remove", "5", "x.com", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("Removed domain: x.com")
    end

    it "aborts when hostname is not on the app" do
      fake.stub(:get, "/apps/5/domains", returns: [])
      result = CliRunner.run("domains:remove", "5", "missing.com", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "domains:clear" do
    it "DELETEs each domain on the app" do
      fake.stub(:get, "/apps/5/domains", returns: [{ "id" => 1, "hostname" => "a.com" }, { "id" => 2, "hostname" => "b.com" }])
      fake.stub(:delete, "/apps/5/domains/1", returns: {})
      fake.stub(:delete, "/apps/5/domains/2", returns: {})
      result = CliRunner.run("domains:clear", "5", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("a.com").and include("b.com")
      expect(fake.calls.count { |c| c.method == :delete }).to eq(2)
    end
  end
end
