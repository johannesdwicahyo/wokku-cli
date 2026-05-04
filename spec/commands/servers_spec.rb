# frozen_string_literal: true

RSpec.describe "servers commands" do
  let(:fake) { FakeApiClient.new }
  after { Wokku::Config.save({}) }

  describe "servers" do
    it "lists servers as a table" do
      fake.stub(:get, "/servers", returns: [
        { "name" => "jkt-01", "host" => "1.2.3.4", "status" => "running" }
      ])
      result = CliRunner.run("servers", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("jkt-01").and include("1.2.3.4").and include("running")
    end

    it "marks the default server with *" do
      Wokku::Config.save("default_server" => "jkt-01")
      fake.stub(:get, "/servers", returns: [
        { "name" => "jkt-01", "host" => "h", "status" => "running" },
        { "name" => "sgp-01", "host" => "h", "status" => "running" }
      ])
      result = CliRunner.run("servers", api: fake)
      lines = result.stdout.lines
      jkt_line = lines.find { |l| l.include?("jkt-01") }
      sgp_line = lines.find { |l| l.include?("sgp-01") }
      expect(jkt_line).to include("*")
      expect(sgp_line).not_to include("*")
    end

    include_examples "respects --json",
      command: "servers",
      path: "/servers",
      fake_response: [{ "name" => "jkt-01", "host" => "h", "status" => "running" }]
  end

  describe "servers:info" do
    it "GETs /servers/:name and prints JSON" do
      fake.stub(:get, "/servers/jkt-01", returns: { "name" => "jkt-01", "host" => "1.2.3.4" })
      result = CliRunner.run("servers:info", "jkt-01", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to include("\"name\": \"jkt-01\"")
    end

    it "aborts when SERVER missing" do
      result = CliRunner.run("servers:info", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end

  describe "servers:default" do
    it "validates the server exists then writes config" do
      fake.stub(:get, "/servers/jkt-01", returns: { "name" => "jkt-01" })
      result = CliRunner.run("servers:default", "jkt-01", api: fake)
      expect(result.exit_code).to eq(0)
      expect(Wokku::Config.load["default_server"]).to eq("jkt-01")
      expect(result.stdout).to include("Default server set to: jkt-01")
    end

    it "--clear removes the default" do
      Wokku::Config.save("default_server" => "jkt-01")
      result = CliRunner.run("servers:default", "--clear", api: fake)
      expect(result.exit_code).to eq(0)
      expect(Wokku::Config.load["default_server"]).to be_nil
      expect(result.stdout).to include("Default server cleared.")
    end

    it "aborts when no arg given" do
      result = CliRunner.run("servers:default", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end
end
