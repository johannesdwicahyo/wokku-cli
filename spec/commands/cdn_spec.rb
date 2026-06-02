# frozen_string_literal: true

RSpec.describe "cdn commands" do
  let(:fake) { FakeApiClient.new }

  describe "cdn:on" do
    it "PATCHes /apps/APP/cdn with enabled=true and prints a propagation note" do
      fake.stub(:patch, "/apps/myapp/cdn", returns: { "enabled" => true })
      result = CliRunner.run("cdn:on", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(enabled: true)
      expect(result.stdout).to match(/cdn: on/i)
      expect(result.stderr).to match(/propagation/i)
    end
  end

  describe "cdn:off" do
    it "PATCHes /apps/APP/cdn with enabled=false" do
      fake.stub(:patch, "/apps/myapp/cdn", returns: { "enabled" => false })
      result = CliRunner.run("cdn:off", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/cdn: off/i)
    end
  end

  describe "cdn" do
    it "reads `cloudflare_proxied` from /apps/APP" do
      fake.stub(:get, "/apps/myapp", returns: { "cloudflare_proxied" => true })
      result = CliRunner.run("cdn", "myapp", api: fake)
      expect(result.stdout).to match(/cdn: on/i)
    end
  end
end
