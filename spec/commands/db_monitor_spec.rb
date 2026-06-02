# frozen_string_literal: true

RSpec.describe "db:monitor command" do
  let(:fake) { FakeApiClient.new }

  it "GETs /databases/DB/monitor and prints the summary" do
    fake.stub(:get, "/databases/mydb/monitor", returns: {
      "active_connections" => 4, "max_connections" => 100,
      "db_size_bytes" => 7_340_032, "cache_hit_ratio" => 0.998,
      "recorded_at" => Time.now.iso8601,
      "top_queries" => [{ "query" => "SELECT 1", "calls" => 5, "mean_ms" => 0.1, "total_ms" => 0.5 }]
    })
    result = CliRunner.run("db:monitor", "mydb", api: fake)
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to match(/conns: 4\s*\/\s*100/i)
    expect(result.stdout).to match(/cache hit: 99\.8%/i)
    expect(result.stdout).to match(/SELECT 1/)
  end

  it "prints a friendly message when no snapshot exists" do
    fake.stub(:get, "/databases/mydb/monitor", returns: { "recorded_at" => nil, "top_queries" => [] })
    result = CliRunner.run("db:monitor", "mydb", api: fake)
    expect(result.stdout).to match(/no stats/i)
  end

  it "aborts when DB missing" do
    result = CliRunner.run("db:monitor", api: fake)
    expect(result.exit_code).not_to eq(0)
  end
end
