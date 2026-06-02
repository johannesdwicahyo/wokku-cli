# frozen_string_literal: true

RSpec.describe "https commands" do
  let(:fake) { FakeApiClient.new }

  describe "https:on" do
    it "PATCHes /apps/APP/https with enabled=true" do
      fake.stub(:patch, "/apps/myapp/https", returns: { "enabled" => true })
      result = CliRunner.run("https:on", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(enabled: true)
      expect(result.stdout).to match(/https redirect: on/i)
    end
  end

  describe "https:off" do
    it "PATCHes /apps/APP/https with enabled=false" do
      fake.stub(:patch, "/apps/myapp/https", returns: { "enabled" => false })
      result = CliRunner.run("https:off", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(enabled: false)
      expect(result.stdout).to match(/https redirect: off/i)
    end
  end

  describe "https" do
    it "GETs the app and prints the current state from `https_redirect`" do
      fake.stub(:get, "/apps/myapp", returns: { "https_redirect" => true })
      result = CliRunner.run("https", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/https redirect: on/i)
    end

    it "aborts when APP is missing" do
      result = CliRunner.run("https", api: fake)
      expect(result.exit_code).not_to eq(0)
    end
  end
end
