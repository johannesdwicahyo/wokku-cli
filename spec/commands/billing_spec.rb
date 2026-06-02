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
    it "GETs /billing/usage and prints the cost summary" do
      fake.stub(:get, "/billing/usage", returns: {
        "period_start" => "2026-06-01T00:00:00Z",
        "period_end"   => "2026-06-30T23:59:59Z",
        "hours_elapsed" => 12.5,
        "current_cost_dollars" => 1.23,
        "projected_cost_dollars" => 4.56,
        "has_payment_method" => true,
        "resources" => [
          { "resource_type" => "AppRecord", "tier_name" => "small", "current_cost_cents" => 100 }
        ]
      })
      result = CliRunner.run("billing:usage", api: fake)
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(/current:\s*\$1\.23/i)
      expect(result.stdout).to match(/projected:\s*\$4\.56/i)
      expect(result.stdout).to match(/payment method:\s*yes/i)
      expect(result.stdout).to match(/AppRecord/)
    end

    it "shows 'no' when no payment method is set" do
      fake.stub(:get, "/billing/usage", returns: {
        "current_cost_dollars" => 0.0,
        "projected_cost_dollars" => 0.0,
        "has_payment_method" => false,
        "resources" => []
      })
      result = CliRunner.run("billing:usage", api: fake)
      expect(result.stdout).to match(/payment method:\s*no/i)
    end
  end
end
