# frozen_string_literal: true

RSpec.describe "logs command" do
  let(:fake) { FakeApiClient.new }

  it "GETs /apps/:id/logs and prints array entries" do
    fake.stub(:get, "/apps/5/logs?lines=100", returns: ["line1", "line2"])
    result = CliRunner.run("logs", "5", api: fake)
    expect(result.exit_code).to eq(0)
    expect(result.stdout).to include("line1").and include("line2")
  end

  it "honors --lines" do
    fake.stub(:get, "/apps/5/logs?lines=500", returns: [])
    result = CliRunner.run("logs", "5", "--lines", "500", api: fake)
    expect(result.exit_code).to eq(0)
    expect(fake.calls.first.path).to eq("/apps/5/logs?lines=500")
  end
end
