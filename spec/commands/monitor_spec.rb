# frozen_string_literal: true

RSpec.describe "monitor command" do
  let(:fake) { FakeApiClient.new }

  it "GETs /apps/APP/monitor and prints totals" do
    fake.stub(:get, "/apps/myapp/monitor", returns: {
      "totals" => { "req_count" => 100, "rpm" => 0.07, "p50_ms" => 30, "p95_ms" => 180, "error_rate" => 0.01 },
      "recent_slow" => [{ "method" => "GET", "path" => "/a", "response_time_ms" => 1500, "status" => 200 }]
    })
    result = CliRunner.run("monitor", "myapp", api: fake)
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to match(/req: 100/i)
    expect(result.stdout).to match(/p95: 180ms/i)
    expect(result.stdout).to match(/error rate: 1\.0%/i)
    expect(result.stdout).to match(%r{/a})
  end

  it "prints a friendly message on empty data" do
    fake.stub(:get, "/apps/myapp/monitor", returns: { "totals" => { "req_count" => 0 }, "recent_slow" => [] })
    result = CliRunner.run("monitor", "myapp", api: fake)
    expect(result.stdout).to match(/no requests/i)
  end
end
