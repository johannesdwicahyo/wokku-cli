# frozen_string_literal: true

RSpec.describe "billing commands" do
  let(:fake) { FakeApiClient.new }

  describe "billing:plan" do
    it "GETs /billing/current_plan and prints the plan + limits" do
      fake.stub(:get, "/billing/current_plan", returns: {
        "plan" => "pro", "max_apps" => 20, "max_databases" => 5
      })
      result = CliRunner.run("billing:plan", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/plan:\s*pro/i)
      expect(result.stdout).to match(/max apps:\s*20/i)
      expect(result.stdout).to match(/max databases:\s*5/i)
    end
  end

  describe "billing:usage" do
    it "is retired and does not call the API" do
      result = CliRunner.run("billing:usage", api: fake)
      expect(result.exit_code).not_to eq(0)
      expect(result.stderr).to include("retired")
      expect(fake.calls).to be_empty
    end
  end
end
