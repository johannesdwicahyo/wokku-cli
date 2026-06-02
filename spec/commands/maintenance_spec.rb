# frozen_string_literal: true

RSpec.describe "maintenance commands" do
  let(:fake) { FakeApiClient.new }

  describe "maintenance:on" do
    it "PATCHes /apps/APP/maintenance with enabled=true" do
      fake.stub(:patch, "/apps/myapp/maintenance", returns: { "enabled" => true })
      result = CliRunner.run("maintenance:on", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(fake.calls.first.body).to eq(enabled: true)
      expect(result.stdout).to match(/maintenance: on/i)
    end
  end

  describe "maintenance:off" do
    it "PATCHes /apps/APP/maintenance with enabled=false" do
      fake.stub(:patch, "/apps/myapp/maintenance", returns: { "enabled" => false })
      result = CliRunner.run("maintenance:off", "myapp", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/maintenance: off/i)
    end
  end

  describe "maintenance" do
    it "reads `maintenance_enabled` from /apps/APP" do
      fake.stub(:get, "/apps/myapp", returns: { "maintenance_enabled" => true })
      result = CliRunner.run("maintenance", "myapp", api: fake)
      expect(result.stdout).to match(/maintenance: on/i)
    end
  end
end
