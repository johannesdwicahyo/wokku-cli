# frozen_string_literal: true

RSpec.describe "metrics command" do
  let(:fake) { FakeApiClient.new }

  it "GETs /apps/APP/metrics and prints the latest summary" do
    fake.stub(:get, "/apps/myapp/metrics", returns: {
      "app_id" => "myapp",
      "minute" => [{ "ts" => Time.now.iso8601, "cpu_pct" => 12.5, "memory_mb" => 230 }],
      "hourly" => []
    })
    result = CliRunner.run("metrics", "myapp", api: fake)
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to match(/cpu: 12\.5%/i)
    expect(result.stdout).to match(/mem: 230/i)
  end

  it "prints a friendly message on empty data" do
    fake.stub(:get, "/apps/myapp/metrics", returns: { "minute" => [], "hourly" => [] })
    result = CliRunner.run("metrics", "myapp", api: fake)
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to match(/no metrics/i)
  end

  it "aborts when APP missing" do
    result = CliRunner.run("metrics", api: fake)
    expect(result.exit_code).not_to eq(0)
  end
end
